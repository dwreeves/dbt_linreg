with

expected as (

  select
    10.0 as const
)

select base.*
from {{ ref('simple_0var_regression_wide') }} as base, expected
where not (
  base.const = expected.const
)
