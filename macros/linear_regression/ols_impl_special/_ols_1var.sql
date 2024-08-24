{% macro _ols_1var(table,
                   endog,
                   exog,
                   add_constant=True,
                   format=None,
                   format_options=None,
                   group_by=None,
                   alpha=None) -%}
{%- set exog_aliased = ['x1'] %}
(with
{%- if alpha %}
_dbt_linreg_cmeans as (
  select
    {{ dbt_linreg._alias_gb_cols(group_by) | indent(4) }}
    avg({{ endog }}) as y,
    avg({{ exog[0] }}) as x1,
    count(*) as ct
  from
    {{ table }}
  {%- if group_by %}
  group by
    {{ dbt_linreg._gb_cols(group_by) | indent(4) }}
  {%- endif %}
),
{%- endif %}
_dbt_linreg_base as (
  select
    {{ dbt_linreg._alias_gb_cols(group_by) | indent(4) }}
    {%- if alpha and add_constant %}
    b.{{ endog }} - _dbt_linreg_cmeans.y as y,
    b.{{ exog[0] }} - _dbt_linreg_cmeans.x1 as x1,
    {%- else %}
    {{ endog }} as y,
    b.{{ exog[0] }} as x1,
    {%- endif %}
    false as fake
  from
    {{ table }} as b
  {%- if alpha %}
  {%- if add_constant %}
  {{ dbt_linreg._join_on_groups(group_by, 'b', '_dbt_linreg_cmeans') | indent(2) }}
  {%- endif %}
  union all
  select
    {{ dbt_linreg._gb_cols(group_by, trailing_comma=True) | indent(4) }}
    0 as y,
    pow(x1 * ct, 0.5) as x1,
    true as fake
  from _dbt_linreg_cmeans
  {%- endif %}
),
_dbt_linreg_final_coefs as (
  select
    {{ dbt_linreg._gb_cols(group_by, trailing_comma=True) | indent(4) }}
    {%- if add_constant %}
    avg({{ dbt_linreg._filter_and_center_if_alpha('b.y', alpha) }})
      - avg({{ dbt_linreg._filter_and_center_if_alpha('b.x1', alpha) }}) * {{ dbt_linreg.regress('b.y', 'b.x1') }}
      as x0_coef,
    {%- endif %}
    {{ dbt_linreg.regress('b.y', 'b.x1', add_constant=add_constant) }} as x1_coef
  from _dbt_linreg_base as b
  {%- if alpha and add_constant %}
  {{ dbt_linreg._join_on_groups(group_by, 'b', '_dbt_linreg_cmeans') | indent(2) }}
  {%- endif %}
  {%- if group_by %}
  group by
    {{ dbt_linreg._gb_cols(group_by) | indent(4) }}
  {%- endif %}
)
{{
  dbt_linreg.final_select(
    exog=exog,
    exog_aliased=['x1'],
    add_constant=add_constant,
    group_by=group_by,
    format=format,
    format_options=format_options,
    calculate_standard_error=False
  )
}}
)
{%- endmacro %}
