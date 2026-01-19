{% macro _ols_0var(table,
                   endog,
                   exog,
                   weights=None,
                   add_constant=True,
                   output=None,
                   output_options=None,
                   group_by=None,
                   alpha=None) -%}
(with _dbt_linreg_final_coefs as (
  select
    {{ dbt_linreg._gb_cols(group_by, trailing_comma=True) }}
    avg({{ endog }}) as x0_coef
  from {{ table }}
  {%- if group_by %}
  group by
    {{ dbt_linreg._gb_cols(group_by) | indent(4) }}
  {%- endif %}
)
{{
  dbt_linreg.final_select(
    exog=[],
    exog_aliased=[],
    add_constant=add_constant,
    group_by=group_by,
    output=output,
    output_options=output_options,
    calculate_standard_error=False
  )
}}
)
{%- endmacro %}
