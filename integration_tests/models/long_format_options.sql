{{
  config(
    materialized="table"
  )
}}
select
  true as strip_quotes, *
  from {{
    dbt_linreg.ols(
      table=ref('simple_matrix'),
      endog='y',
      exog=['"xa"', 'xb'],
      output='long',
      output_options={
        'constant_name': 'constant_term',
        'variable_column_name': 'vname',
        'coefficient_column_name': 'co',
        'strip_quotes': True
      }
    )
  }} as linreg1

union all

select
  false as strip_quotes, *
  from {{
    dbt_linreg.ols(
      table=ref('simple_matrix'),
      endog='y',
      exog=['"xa"', 'xb'],
      output='long',
      output_options={
        'constant_name': 'constant_term',
        'variable_column_name': 'vname',
        'coefficient_column_name': 'co',
        'strip_quotes': False
      }
    )
  }} as linreg2
