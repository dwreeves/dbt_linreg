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
    alpha=1.0,
    output='long',
    add_constant=false
  )
}} as linreg
