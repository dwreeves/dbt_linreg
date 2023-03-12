{{
  config(
    materialized="table"
  )
}}
select * from {{
  dbt_linreg.ols(
    table=ref('simple_matrix'),
    endog='y',
    exog=['xa', 'xb', 'xc', 'xd', 'xe'],
    format='long',
    format_options={'round': 5}
  )
}}
