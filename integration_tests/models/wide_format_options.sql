{{
  config(
    materialized="table"
  )
}}
select
  *
  from {{
    dbt_linreg.ols(
      table=ref('simple_matrix'),
      endog='y',
      exog=['"xa"', 'xb'],
      output='wide',
      output_options={
        'variable_column_prefix': 'foo',
        'variable_column_suffix': '_bar',
        'constant_name': 'constant_term'
      }
    )
  }} as linreg
