{{
  config(
    materialized="table",
    enabled=False
  )
}}
select * from {{
  dbt_linreg.ols(
    table=ref('collinear_matrix'),
    endog='y',
    exog=['x1', 'x2', 'x3', 'x4'],
    format='long',
    alpha=0.6,
    weights='abs(x5)',
    method='fwl'
  )
}}