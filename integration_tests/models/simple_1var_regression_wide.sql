{{
  config(
    materialized="table"
  )
}}
select * from {{
  dbt_linreg.ols(
    table=ref('simple_matrix'),
    endog='y',
    exog=['xa'],
    output='wide',
    output_options={'round': 5}
  )
}} as linreg
