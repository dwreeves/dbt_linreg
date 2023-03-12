with

expected as (

  select
    10.0 as const,
    5.0 as xa,
    7.0 as xb,
    9.0 as xc,
    11.0 as xd
)

select base.*
from {{ ref('simple_4var_regression_wide') }} as base, expected
where not (
  base.const = expected.const
  and base.xa = expected.xa
  and base.xb = expected.xb
  and base.xc = expected.xc
  and base.xd = expected.xd
)
