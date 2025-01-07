with

expected as (

  select
    10.0 as const,
    5.0 as xa
)

select
  expected.const as expected_const,
  base.const as actual_const,
  expected.xa as expected_xa,
  base.xa as actual_xa
from {{ ref('simple_1var_regression_wide') }} as base, expected
where not (
  abs(base.const - expected.const) <= {{ var("_test_precision_simple_matrix") }}
  and abs(base.xa - expected.xa) <= {{ var("_test_precision_simple_matrix") }}
)
