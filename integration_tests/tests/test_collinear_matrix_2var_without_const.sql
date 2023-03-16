with

expected as (

  select 'x1' as variable_name, 63.18154691334764 as coefficient
  union all
  select 'x2' as variable_name, 55.39820150046505 as coefficient

)

select base.variable_name
from {{ ref('collinear_matrix_2var_without_const') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where
  round(base.coefficient, 7) - round(expected.coefficient, 7)
  or base.coefficient is null
