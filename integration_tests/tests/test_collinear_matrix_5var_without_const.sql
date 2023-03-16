with

expected as (

  select 'x1' as variable_name, 11.392300499659957 as coefficient
  union all
  select 'x2' as variable_name, 2.333060182571783 as coefficient
  union all
  select 'x3' as variable_name, 21.895814737788875 as coefficient
  union all
  select 'x4' as variable_name, 3.4480236159406785 as coefficient
  union all
  select 'x5' as variable_name, 15.766951731565559 as coefficient

)

select base.variable_name
from {{ ref('collinear_matrix_5var_without_const') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where
  round(base.coefficient, 7) - round(expected.coefficient, 7)
  or base.coefficient is null
