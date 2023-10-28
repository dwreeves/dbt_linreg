{{
  config(
    materialized="table"
  )
}}
with base as (
  select
    y,
    xa,
    xa as xb
  from {{ ref('simple_matrix') }}
)

select * from {{
  dbt_linreg.ols(
    table='base',
    endog='y',
    exog=['xa', 'xb']
  )
}} as linreg
