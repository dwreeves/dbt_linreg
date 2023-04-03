{{
  config(
    materialized="table"
  )
}}
select * from {{
  dbt_linreg.ols(
    table=ref('groups_matrix'),
    endog='y',
    exog=['x1', 'x2', 'x3'],
    group_by=['gb_var'],
    format='long',
    method='fwl'
  )
}}
order by gb_var, variable_name
