with

expected as (

  select
    10.0 as const,
    5.0 as xa,
    7.0 as xb,
    9.0 as xc,
    11.0 as xd,
    13.0 as xe
)

select
  expected.const as expected_const,
  base.const as actual_const,
  expected.xa as expected_xa,
  base.xa as actual_xa,
  expected.xb as expected_xb,
  base.xb as actual_xb,
  expected.xc as expected_xc,
  base.xc as actual_xc,
  expected.xd as expected_xd,
  base.xd as actual_xd,
  expected.xe as expected_xe,
  base.xe as actual_xe
from {{ ref('simple_5var_regression_wide') }} as base, expected
where not (
  abs(base.const - expected.const) <= {{ var("_test_precision_simple_matrix") }}
  and abs(base.xa - expected.xa) <= {{ var("_test_precision_simple_matrix") }}
  and abs(base.xb - expected.xb) <= {{ var("_test_precision_simple_matrix") }}
  and abs(base.xc - expected.xc) <= {{ var("_test_precision_simple_matrix") }}
  and abs(base.xd - expected.xd) <= {{ var("_test_precision_simple_matrix") }}
  and abs(base.xe - expected.xe) <= {{ var("_test_precision_simple_matrix") }}
)
