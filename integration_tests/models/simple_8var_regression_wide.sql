{{
  config(
    materialized="view",
    tags=["perftest"],
    enabled=False
  )
}}
select * from {{
  dbt_linreg.ols(
    table=ref('simple_matrix'),
    endog='y',
    exog=['xa', 'xb', 'xc', 'xd', 'xe', 'xf', 'xg', 'xh'],
    format='wide',
  )
}}
