with

expected as (

  select 'const' as variable_name, 10.0 as coefficient

)

select
  coalesce(base.variable_name, expected.variable_name) as variable_name,
  expected.coefficient as expected_coefficient,
  base.coefficient as actual_coefficient
from {{ ref('simple_0var_regression_long_fwl') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where
  abs(base.coefficient - expected.coefficient) > {{ var("_test_precision_simple_matrix") }}
  or base.coefficient is null
