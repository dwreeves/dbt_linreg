with

expected as (

  select 'const' as variable_name, 10.0 as coefficient
  union all
  select 'xa' as variable_name, 5.0 as coefficient
  union all
  select 'xb' as variable_name, 7.0 as coefficient
  union all
  select 'xc' as variable_name, 9.0 as coefficient
  union all
  select 'xd' as variable_name, 11.0 as coefficient

)

select
  coalesce(base.variable_name, expected.variable_name) as variable_name,
  expected.coefficient as expected_coefficient,
  base.coefficient as actual_coefficient
from {{ ref('simple_4var_regression_long') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where
  abs(base.coefficient - expected.coefficient) > {{ var("_test_precision_simple_matrix") }}
  or base.coefficient is null
