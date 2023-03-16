{% macro _join_on_groups(group_by, join_from, join_to) -%}
{%- if not group_by %}
cross join {{ join_to }}
{%- else %}
inner join {{ join_to }}
on
  {%- for _ in group_by %}
  {{ join_from }}.gb{{ loop.index }} = {{ join_to }}.gb{{ loop.index }}
  {%- if not loop.last -%}
  and
  {%- endif %}
  {%- endfor %}
{%- endif %}
{%- endmacro %}

{% macro _traverse_slopes(step, x) -%}
  {%- set li = [] %}
  {%- for i in x %}
    {%- for j in x %}
      {%- set remaining = x.copy() %}
      {%- if i != j %}
      {%- do remaining.remove(i) %}
      {%- do remaining.remove(j) %}
      {%- set comb = modules.itertools.combinations(remaining, step - 1) %}
      {%- for c in comb %}
        {%- do li.append((i, j, c)) %}
      {%- endfor %}
      {%- endif %}
    {%- endfor %}
  {%- endfor %}
  {{ return(li) }}
{% endmacro %}

{% macro _traverse_intercepts(step, x) -%}
  {%- set li = [] %}
  {%- for i in x %}
    {%- set remaining = x.copy() %}
    {%- do remaining.remove(i) %}
    {%- set comb = modules.itertools.combinations(remaining, step) %}
    {%- for c in comb %}
      {%- set ortho = [] %}
      {%- if c %}
        {%- for b in c %}
          {%- set _c = (c | list) %}
          {%- do _c.remove(b) %}
          {%- do ortho.append([b] + (modules.itertools.combinations(_c, step - 1) | list)) %}
        {%- endfor %}
      {%- endif %}
      {%- do li.append((i, ortho)) %}
    {%- endfor %}
  {%- endfor %}
  {{ return(li) }}
{% endmacro %}

{% macro _filter_if_alpha(i, alpha) %}
{% if alpha %}
  {{ return('case when not fake then ' ~ i ~ ' end') }}
{% else %}
  {{ return(i) }}
{% endif %}
{% endmacro %}

{% macro _filter_and_center_if_alpha(i, alpha, base_prefix='') %}
{% if alpha %}
  {{ return('case when not fake then ' ~ base_prefix ~ i ~ ' + _dbt_linreg_cmeans.' ~ i ~ ' end') }}
{% else %}
  {{ return(i) }}
{% endif %}
{% endmacro %}

{% macro _orth_x_slope(x, o) -%}
  {%- if o %}
    {{ return(x ~ '_' ~ (o | join(''))) }}
  {%- else %}
    {{ return(x) }}
  {%- endif %}
{% endmacro %}

{% macro _orth_x_intercept(x, o) -%}
  {%- set li = []  %}
  {%- for c in o %}
    {%- do li.append(c[0]) %}
  {%- endfor %}
  {{ return(x ~ '_' ~ (li | join(''))) }}
{% endmacro %}

{% macro _ols_fwl(table,
                  endog,
                  exog,
                  add_constant=True,
                  format=None,
                  format_options=None,
                  group_by=None,
                  alpha=None) -%}
{%- if (exog | length) == 0 %}
  {% do log('Note: exog was empty; running regression on constant term only.') %}
  {{ return(dbt_linreg._ols_0var(
    table=table,
    endog=endog,
    exog=exog,
    add_constant=add_constant,
    format=format,
    format_options=format_options,
    group_by=group_by,
    alpha=alpha
  )) }}
{%- elif (exog | length) == 1 %}
  {{ return(dbt_linreg._ols_1var(
    table=table,
    endog=endog,
    exog=exog,
    add_constant=add_constant,
    format=format,
    format_options=format_options,
    group_by=group_by,
    alpha=alpha
  )) }}
{%- endif %}
{%- set exog_aliased = dbt_linreg._alias_exog(exog) %}
(with
{%- if alpha %}
_dbt_linreg_cmeans as (
  select
    {{ dbt_linreg._alias_gb_cols(group_by) | indent(4) }}
    avg({{ endog }}) as y,
    {%- for i in exog_aliased %}
    avg({{ exog[loop.index0] }}) as {{ i }},
    {%- endfor %}
    count(*) as ct
  from
    {{ table }}
  {%- if group_by %}
  group by
    {{ dbt_linreg._gb_cols(group_by) | indent(4) }}
  {%- endif %}
),
{%- endif %}
_dbt_linreg_step0 as (
  select
    {{ dbt_linreg._alias_gb_cols(group_by) | indent(4) }}
    {%- if alpha and add_constant %}
    b.{{ endog }} - _dbt_linreg_cmeans.y as y,
    {%- for i in exog_aliased %}
    b.{{ exog[loop.index0] }} - _dbt_linreg_cmeans.{{ i }} as {{ i }},
    {%- endfor %}
    {%- else %}
    {{ endog }} as y,
    {%- for i in exog_aliased %}
    b.{{ exog[loop.index0] }} as {{ i }},
    {%- endfor %}
    {%- endif %}
    false as fake
  from
    {{ table }} as b
  {%- if alpha %}
  {%- if add_constant %}
  {{ dbt_linreg._join_on_groups(group_by, 'b', '_dbt_linreg_cmeans') | indent(2) }}
  {%- endif %}
  {%- for i in exog_aliased %}
  {%- set i_idx = loop.index0 %}
  union all
  select
    {{ dbt_linreg._gb_cols(group_by, trailing_comma=True) | indent(4) }}
    0 as y,
    {%- for j in exog_aliased %}
    {%- if i == j %}
    pow({{ alpha[i_idx] }} * ct, 0.5) as {{ j }},
    {%- else %}
    0 as {{ j }},
    {%- endif %}
    {%- endfor %}
    true as fake
  from _dbt_linreg_cmeans as cmeans
  {%- endfor %}
  {%- endif %}
),
{% for step in range(1, (exog | length)) %}
_dbt_linreg_step{{ step }} as (
  with
  _coefs as (
    select
      {{ dbt_linreg._gb_cols(group_by, trailing_comma=True) | indent(6) }}
      {#- Slope terms #}

      {%- for _y, _x, _o in dbt_linreg._traverse_slopes(step, exog_aliased) %}
      {%- set _c = dbt_linreg._orth_x_slope(_x, _o) %}
      {{ dbt_linreg.regress(_y, _c, add_constant=add_constant) }} as {{ _y }}_{{ _c }}_coef,
      {%- endfor %}

      {#- Constant terms #}
      {%- if add_constant %}
      {%- for _y, _o in dbt_linreg._traverse_intercepts(step, exog_aliased) %}
      avg({{ dbt_linreg._filter_if_alpha(_y, alpha) }})
      {%- for _yi, _xi in _o %}
      {%- set _ci = dbt_linreg._orth_x_slope(_yi, _xi) %}
        - avg({{ dbt_linreg._filter_if_alpha(_yi, alpha) }}) * {{ dbt_linreg.regress(_yi, _ci) }}
      {%- endfor %}
        as {{ dbt_linreg._orth_x_intercept(_y, _o) }}_const
      {%- if not loop.last -%}
      ,
      {%- endif -%}
      {%- endfor %}
      {%- endif %}
    from _dbt_linreg_step{{ step - 1 }}
    {%- if group_by %}
    group by
      {{ dbt_linreg._gb_cols(group_by) | indent(6) }}
    {%- endif %}
  )
  select
    {{ dbt_linreg._gb_cols(group_by, prefix='b', trailing_comma=True) | indent(4) }}
    y,
    {%- for i in exog_aliased %}
    {{ i }},
    {%- endfor %}
    fake,
    {%- for _y, _o in dbt_linreg._traverse_intercepts(step, exog_aliased) %}
    {{ _y }}
    {%- for _yi, _xi in _o %}
    {%- set _ci = dbt_linreg._orth_x_slope(_yi, _xi) %}
      - {{ _y }}_{{ _ci }}_coef * {{ _yi }}
    {%- endfor %}
      {%- set _c = dbt_linreg._orth_x_intercept(_y, _o) %}
      {%- if add_constant %}
      - {{ _c }}_const
      {%- endif %}
      as {{ _c }}
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from _dbt_linreg_step0 as b
  {{ dbt_linreg._join_on_groups(group_by, 'b', '_coefs') | indent(2) }}
),
{%- if loop.last %}
_dbt_linreg_final_coefs as (
  select
    {%- if add_constant %}
    {{ dbt_linreg._gb_cols(group_by, trailing_comma=True) | indent(4) }}
    avg({{ dbt_linreg._filter_and_center_if_alpha('y', alpha, base_prefix='b.') }})
      {%- for _x, _o in dbt_linreg._traverse_intercepts(step, exog_aliased) %}
      - avg({{ dbt_linreg._filter_and_center_if_alpha(_x, alpha, base_prefix='b.') }}) * {{ dbt_linreg.regress('b.y', dbt_linreg._orth_x_intercept('b.' ~ _x, _o)) }}
      {%- endfor %}
      as const_coef,
    {%- endif %}
    {%- for _x, _o in dbt_linreg._traverse_intercepts(step, exog_aliased) %}
    {{ dbt_linreg.regress('b.y', dbt_linreg._orth_x_intercept(_x, _o), add_constant=add_constant) }} as {{ _x }}_coef
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from _dbt_linreg_step{{ step }} as b
  {%- if alpha and add_constant %}
  {{ dbt_linreg._join_on_groups(group_by, 'b', '_dbt_linreg_cmeans') | indent(2) }}
  {%- endif %}
  {%- if group_by %}
  group by
    {{ dbt_linreg._gb_cols(group_by) | indent(4) }}
  {%- endif %}
)
{%- endif %}
{%- endfor %}
{{
  dbt_linreg.final_select(
    exog=exog,
    exog_aliased=exog_aliased,
    add_constant=add_constant,
    group_by=group_by,
    format=format,
    format_options=format_options
  )
}}
)
{%- endmacro %}
