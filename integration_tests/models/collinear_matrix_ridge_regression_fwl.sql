{{
  config(
    materialized="table"
  )
}}
select * from {{
  dbt_linreg.ols(
    table=ref('collinear_matrix'),
    endog='y',
    exog=['x1', 'x2', 'x3', 'x4', 'x5'],
    output='long',
    alpha=0.01,
    method='fwl'
  )
}} as linreg
