{{
  config(
    materialized="table",
    tags=["skip-postgres"]
  )
}}
select * from {{
  dbt_linreg.ols(
    table=ref('collinear_matrix'),
    endog='y',
    exog=['x1', 'x2', 'x3', 'x4', 'x5'],
    output='long',
    method='chol'
  )
}} as linreg
