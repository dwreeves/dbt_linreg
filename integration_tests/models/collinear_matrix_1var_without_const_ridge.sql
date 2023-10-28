{{
  config(
    materialized="table"
  )
}}
select * from {{
  dbt_linreg.ols(
    table=ref('collinear_matrix'),
    endog='y',
    exog=['x1'],
    alpha=2.0,
    format='long',
    add_constant=False
  )
}} as linreg
