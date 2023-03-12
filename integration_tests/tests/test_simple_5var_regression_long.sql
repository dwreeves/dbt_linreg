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
  union all
  select 'xe' as variable_name, 13.0 as coefficient

)

select base.variable_name
from {{ ref('simple_5var_regression_long') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where base.coefficient != expected.coefficient or base.coefficient is null
