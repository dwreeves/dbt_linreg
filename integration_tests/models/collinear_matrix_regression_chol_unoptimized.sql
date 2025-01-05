{{
  config(
    materialized="table",
    tags=["skip-postgres", "skip-clickhouse"]
  )
}}
select * from {{
  dbt_linreg.ols(
    table=ref('collinear_matrix'),
    endog='y',
    exog=['x1', 'x2', 'x3', 'x4', 'x5'],
    output='long',
    method='chol',
    method_options={'subquery_optimization': False}
  )
}} as linreg
