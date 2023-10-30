{{
  config(
    materialized="view",
    enabled=False,
    tags=["skip-postgres"]
  )
}}
select * from {{
  dbt_linreg.ols(
    table=ref('simple_matrix'),
    endog='y',
    exog=['xa', 'xb', 'xc', 'xd', 'xe', 'xf', 'xg', 'xh', 'xi', 'xj'],
    format='long',
    format_options={'round': 5}
  )
}} as linreg
