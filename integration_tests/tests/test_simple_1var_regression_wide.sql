with

expected as (

  select
    10.0 as const,
    5.0 as xa
)

select base.*
from {{ ref('simple_1var_regression_wide') }} as base, expected
where not (
  base.const = expected.const
  and base.xa = expected.xa
)
