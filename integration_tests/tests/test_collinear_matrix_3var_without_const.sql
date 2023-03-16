with

expected as (

  select 'x1' as variable_name, 20.090207982897063 as coefficient
  union all
  select 'x2' as variable_name, -16.533211090826203 as coefficient
  union all
  select 'x3' as variable_name, 35.00389104686492 as coefficient

)

select base.variable_name
from {{ ref('collinear_matrix_3var_without_const') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where
  round(base.coefficient, 7) - round(expected.coefficient, 7)
  or base.coefficient is null
