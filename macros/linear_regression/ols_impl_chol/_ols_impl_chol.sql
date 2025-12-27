{# In some warehouses, you can reference newly created column aliases
   in the query you wrote.
   If that's not available, the previous calc will be in the dict. #}

{% macro _cell_or_alias(i, j, d, prefix=none, isa=none) %}
  {% if isa is not none %}
    {% if isa %}
      {{ return((prefix if prefix is not none else '') ~ 'i' ~ i ~ 'j' ~ j) }}
    {% else %}
      {{ return(d[(i, j)]) }}
    {% endif %}
  {% endif %}
  {{ return(
    adapter.dispatch('_cell_or_alias', 'dbt_linreg')
    (i, j, d, prefix, isa)
  ) }}
{% endmacro %}

{% macro default___cell_or_alias(i, j, d, prefix=none, isa=none) %}
  {{ return(d[(i, j)]) }}
{% endmacro %}

{% macro snowflake___cell_or_alias(i, j, d, prefix=none, isa=none) %}
  {{ return((prefix if prefix is not none else '') ~ 'i' ~ i ~ 'j' ~ j) }}
{% endmacro %}

{% macro duckdb___cell_or_alias(i, j, d, prefix=none, isa=none) %}
  {{ return((prefix if prefix is not none else '') ~ 'i' ~ i ~ 'j' ~ j) }}
{% endmacro %}

{% macro clickhouse___cell_or_alias(i, j, d, prefix=none, isa=none) %}
  {{ return((prefix if prefix is not none else '') ~ 'i' ~ i ~ 'j' ~ j) }}
{% endmacro %}

{% macro _safe_sqrt(x, safe=True) %}
  {{ return(
    adapter.dispatch('_safe_sqrt', 'dbt_linreg')
    (x, safe)
  ) }}
{% endmacro %}

{% macro default___safe_sqrt(x, safe=True) %}
  {% if safe %}
    {{ return('case when ('~x~') >= 0 then sqrt('~x~') end') }}
  {% endif %}
  {{ return('sqrt('~x~')') }}
{% endmacro %}

{% macro bigquery___safe_sqrt(x, safe=True) %}
  {% if safe %}
    {{ return('safe.sqrt('~x~')') }}
  {% endif %}
  {{ return('sqrt('~x~')') }}
{% endmacro %}

{% macro _cholesky_decomposition(li, subquery_optimization=true, safe=true, isa=none) %}
  {% set d = {} %}
  {% for i in li %}
    {% for j in range(li[0], i + 1) %}
      {% if i == li[0] and j == li[0] %}
        {% do d.update({(i, j): dbt_linreg._safe_sqrt(x='x'~i~'x'~j, safe=safe)}) %}
      {% else %}
        {% set ns = namespace() %}
        {% set ns.s = 'x'~j~'x'~i %}
        {% for k in range(li[0], j) %}
          {% if subquery_optimization and i != j %}
            {% set ns.s = ns.s~'-'~dbt_linreg._cell_or_alias(i=i, j=k, d=d, isa=isa)~'*i'~j~'j'~k %}
          {% else %}
            {% set ns.s = ns.s~'-'~dbt_linreg._cell_or_alias(i=i, j=k, d=d, isa=isa)~'*'~dbt_linreg._cell_or_alias(i=j, j=k, d=d, isa=isa) %}
          {% endif %}
        {% endfor %}
        {% if i == j %}
          {% do d.update({(i, j): dbt_linreg._safe_sqrt(x=ns.s, safe=safe)}) %}
        {% else %}
          {% if safe %}
            {% do d.update({(i, j): '('~ns.s~')/nullif('~dbt_linreg._cell_or_alias(i=j, j=j, d=d, isa=isa) ~ ', 0)'}) %}
          {% else %}
            {% do d.update({(i, j): '('~ns.s~')/'~dbt_linreg._cell_or_alias(i=j, j=j, d=d, isa=isa)}) %}
          {% endif %}
        {% endif %}
      {% endif %}
    {% endfor %}
  {% endfor %}
  {{ return(d) }}
{% endmacro %}

{% macro _forward_substitution(li, safe=true, isa=none) %}
  {% set d = {} %}
  {% for i, j in dbt_linreg._combinations_with_replacement(li, 2) %}
    {% set ns = namespace() %}
    {% if i == j %}
      {% set ns.numerator = '1' %}
    {% else %}
      {% set ns.numerator = '(' %}
      {% for k in range(i, j) %}
        {% set ns.numerator = ns.numerator~'-i'~j~'j'~k~'*'~dbt_linreg._cell_or_alias(i=i, j=k, d=d, prefix="inv_", isa=isa) %}
      {% endfor %}
      {% set ns.numerator = ns.numerator~')' %}
    {% endif %}
    {% if safe %}
      {% do d.update({(i, j): '('~ns.numerator~'/nullif(i'~j~'j'~j~', 0))'}) %}
    {% else %}
      {% do d.update({(i, j): '('~ns.numerator~'/i'~j~'j'~j~')'}) %}
    {% endif %}
  {% endfor %}
  {{ return(d) }}
{% endmacro %}

{% macro _ols_chol(table,
                   endog,
                   exog,
                   weights=None,
                   add_constant=True,
                   output=None,
                   output_options=None,
                   group_by=None,
                   alpha=None,
                   method_options=None) -%}
{%- if (exog | length) == 0 %}
  {% do log('Note: exog was empty; running regression on constant term only.') %}
  {{ return(dbt_linreg._ols_0var(
    table=table,
    endog=endog,
    exog=exog,
    add_constant=add_constant,
    output=output,
    output_options=output_options,
    group_by=group_by,
    alpha=alpha
  )) }}
{%- endif %}
{%- set subquery_optimization = dbt_linreg._get_method_option('chol', 'subquery_optimization', method_options, true) %}
{%- set safe_mode = dbt_linreg._get_method_option('chol', 'safe', method_options, true) %}
{% set isa = dbt_linreg._get_method_option('chol', 'intra_select_aliasing', method_options) %}
{%- set calculate_standard_error =  dbt_linreg._get_output_option('calculate_standard_error', output_options, (not alpha) and output == 'long') %}
{%- if alpha and calculate_standard_error %}
  {% do log(
    'Warning: Standard errors are NOT designed to take into account ridge regression regularization.'
  ) %}
{%- endif %}
{%- if add_constant %}
  {% set xmin = 0 %}
{%- else %}
  {% set xmin = 1 %}
{%- endif %}
{%- set xcols = (range(xmin, (exog | length) + 1) | list) %}
{%- set upto = (xcols | length) %}
{%- set exog_aliased = dbt_linreg._alias_exog(exog) %}
(with
_dbt_linreg_base as (
  select
    {{ dbt_linreg._alias_gb_cols(group_by) | indent(4) }}
    {{ endog }} as y,
    {%- if add_constant %}
    1 as x0,
    {%- endif %}
    {%- for i in range(1, (exog | length) + 1) %}
    b.{{ exog[loop.index0] }} as x{{ i }}
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from
    {{ table }} as b
),
_dbt_linreg_xtx as (
  select
    {{ dbt_linreg._gb_cols(group_by, trailing_comma=True) | indent(4) }}
    {%- for i, j in dbt_linreg._combinations_with_replacement(xcols, 2) %}
    {%- if alpha and i == j and i > 0 %}
    sum(b.x{{ i }} * b.x{{ j }} + {{ alpha[i-1] }}) as x{{ i }}x{{ j }}
    {%- else %}
    sum(b.x{{ i }} * b.x{{ j }}) as x{{ i }}x{{ j }}
    {%- endif %}
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from _dbt_linreg_base as b
  {%- if group_by %}
  group by
    {{ dbt_linreg._gb_cols(group_by) | indent(4) }}
  {%- endif %}
),
_dbt_linreg_chol as (

  {%- set d = dbt_linreg._cholesky_decomposition(li=xcols, subquery_optimization=subquery_optimization, safe=safe_mode, isa=isa) %}
  {%- if subquery_optimization %}
  {%- for i in (xcols | reverse) %}
  select
    *,
    {%- for j in range(xmin, i + 1) %}
    {{ d[(i, j)] }} as i{{ i }}j{{ j }}
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  {%- if not loop.last %}
  from (
  {%- else %}
  from _dbt_linreg_xtx{% for close_ct in range(upto - 1) %}) as ic{{ close_ct }}{% endfor %}
  {%- endif %}
  {%- endfor %}
  {%- else %}
  select
    {{ dbt_linreg._gb_cols(group_by, trailing_comma=True) | indent(4) }}
    {%- for k, v in d.items() %}
    {{ v }} as {{ 'i'~k[0]~'j'~k[1] }}
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from _dbt_linreg_xtx
    {%- endif %}
),
_dbt_linreg_inverse_chol as (
  {#- The optimal way to calculate is to do each diagonal at a time. #}
  {%- set d = dbt_linreg._forward_substitution(li=xcols, safe=safe_mode, isa=isa) %}
  {%- if subquery_optimization %}
  {%- for gap in (range(0, upto) | reverse) %}
  select *,
    {%- for j in range(gap + xmin, upto + xmin) %}
    {%- set i = j - gap %}
    {{ d[(i, j)] }} as inv_i{{ i }}j{{ j }}
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  {%- if not loop.last %}
  from (
  {%- else %}
  from _dbt_linreg_chol{% for close_ct in range(upto - 1) %}) as ic{{ close_ct }}{% endfor %}
  {%- endif %}
  {%- endfor %}
  {%- else %}
  select
    {{ dbt_linreg._gb_cols(group_by, trailing_comma=True) | indent(4) }}
    {%- for k, v in d.items() %}
    {{ v }} as inv_{{ 'i'~k[0]~'j'~k[1] }}
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from _dbt_linreg_chol
  {%- endif %}
),
_dbt_linreg_inverse_xtx as (
  select
    {{ dbt_linreg._gb_cols(group_by, trailing_comma=True) | indent(4) }}
    {%- for i, j in dbt_linreg._combinations_with_replacement(xcols, 2) %}
    {%- if not add_constant %}
      {%- set upto = upto + 1 %}
    {%- endif %}
    {%- for k in range(j, upto) %}
    inv_i{{ i }}j{{ k }} * inv_i{{ j }}j{{ k }}{%- if not loop.last %} + {% endif -%}
    {%- endfor %}
    as inv_x{{ i }}x{{ j }}
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from _dbt_linreg_inverse_chol
),
_dbt_linreg_final_coefs as (
  select
    {{ dbt_linreg._gb_cols(group_by, trailing_comma=True, prefix='b') | indent(4) }}
    {%- for x1 in xcols %}
    sum((
    {%- for x2 in xcols %}
      {%- if x2 > x1 %}
      b.x{{ x2 }} * inv_x{{ x1 }}x{{ x2 }}
      {%- else %}
      b.x{{ x2 }} * inv_x{{ x2 }}x{{ x1 }}
      {%- endif %}
      {%- if not loop.last %} + {% endif -%}
    {%- endfor %}
    ) * b.y) as x{{ x1 }}_coef
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from
    _dbt_linreg_base as b
  {{ dbt_linreg._join_on_groups(group_by, 'b', '_dbt_linreg_inverse_xtx') | indent(2) }}
  {%- if group_by %}
  group by
    {{ dbt_linreg._gb_cols(group_by, prefix='b') | indent(4) }}
  {%- endif %}
){%- if calculate_standard_error %},
_dbt_linreg_resid as (
  select
    {{ dbt_linreg._gb_cols(group_by, trailing_comma=True, prefix='b') | indent(4) }}
    avg(pow(y
      {%- for x in xcols %}
      - x{{ x }} * x{{ x }}_coef
      {%- endfor %}
    , 2)) as resid_square_mean,
    count(*) as n
  from
    _dbt_linreg_base as b
  {{ dbt_linreg._join_on_groups(group_by, 'b', '_dbt_linreg_final_coefs') | indent(2) }}
  {%- if group_by %}
  group by
    {{ dbt_linreg._gb_cols(group_by, prefix='b') | indent(2) }}
  {%- endif %}
),
_dbt_linreg_stderrs as (
  select
    {{ dbt_linreg._gb_cols(group_by, trailing_comma=True, prefix='b') | indent(4) }}
    {%- for x in xcols %}
    sqrt(inv_x{{ x }}x{{ x }} * resid_square_mean * n / (n - {{ upto }})) as x{{ x }}_stderr
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from
    _dbt_linreg_resid as b
  {{ dbt_linreg._join_on_groups(group_by, 'b', '_dbt_linreg_inverse_xtx') | indent(2) }}
)
{%- endif %}
{{
  dbt_linreg.final_select(
    exog=exog,
    exog_aliased=exog_aliased,
    add_constant=add_constant,
    group_by=group_by,
    output=output,
    output_options=output_options,
    calculate_standard_error=calculate_standard_error
  )
}})
{% endmacro %}
