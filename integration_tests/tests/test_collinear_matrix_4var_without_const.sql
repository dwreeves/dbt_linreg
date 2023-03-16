with

expected as (

  select 'x1' as variable_name, 20.587532776354163 as coefficient
  union all
  select 'x2' as variable_name, -20.41001520357013 as coefficient
  union all
  select 'x3' as variable_name, 35.084935774341524 as coefficient
  union all
  select 'x4' as variable_name, 1.8960558858899716 as coefficient

)

select base.variable_name
from {{ ref('collinear_matrix_4var_without_const') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where
  round(base.coefficient, 7) - round(expected.coefficient, 7)
  or base.coefficient is null
