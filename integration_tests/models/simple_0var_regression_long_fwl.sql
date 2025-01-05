{{
  config(
    materialized="table"
  )
}}
select * from {{
  dbt_linreg.ols(
    table=ref('simple_matrix'),
    endog='y',
    exog=[],
    output='long',
    output_options={'round': 5}
  )
}} as linreg
