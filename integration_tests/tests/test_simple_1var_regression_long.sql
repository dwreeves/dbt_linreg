with

expected as (

  select 'const' as variable_name, 10.0 as coefficient
  union all
  select 'xa' as variable_name, 5.0 as coefficient

)

select base.variable_name
from {{ ref('simple_1var_regression_long') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where base.coefficient != expected.coefficient or base.coefficient is null
