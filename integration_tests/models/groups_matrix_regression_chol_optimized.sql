{{
  config(
    materialized="table",
    tags=["skip-postgres"]
  )
}}
select * from {{
  dbt_linreg.ols(
    table=ref('groups_matrix'),
    endog='y',
    exog=['x1', 'x2', 'x3'],
    group_by=['gb_var'],
    output='long',
    method='chol',
    method_options={'subquery_optimization': True}
  )
}} as linreg
order by gb_var, variable_name
