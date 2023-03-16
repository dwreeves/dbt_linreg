with

expected as (

  select 'x1' as variable_name, 30.500076644845674 as coefficient

)

select base.variable_name
from {{ ref('collinear_matrix_1var_without_const') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where
  round(base.coefficient, 7) - round(expected.coefficient, 7)
  or base.coefficient is null
