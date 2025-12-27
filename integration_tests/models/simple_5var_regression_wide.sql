{{
  config(
    materialized="table",
    tags=["skip-postgres"]
  )
}}
select * from {{
  dbt_linreg.ols(
    table=ref('simple_matrix'),
    endog='y',
    exog=['xa', 'xb', 'xc', 'xd', 'xe'],
    output='wide',
    output_options={'round': 5}
  )
}} as linreg
