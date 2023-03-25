with

expected as (

  select 'const' as variable_name, 10.0 as coefficient

)

select base.variable_name
from {{ ref('simple_2var_regression_long_chol') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where base.coefficient != expected.coefficient or base.coefficient is null
