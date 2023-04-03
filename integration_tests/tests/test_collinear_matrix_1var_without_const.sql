with

expected as (

  select 'x1' as variable_name, 30.500076644845674 as coefficient, 0.8396121329329627 as standard_error, 36.326388636502585 as t_statistic

)

select base.variable_name
from {{ ref('collinear_matrix_1var_without_const') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where
  round(base.coefficient, 7) != round(expected.coefficient, 7)
  or round(base.standard_error, 7) != round(expected.standard_error, 7)
  or round(base.t_statistic, 7) != round(expected.t_statistic, 7)
  or base.coefficient is null
  or base.standard_error is null
  or base.t_statistic is null
  or expected.coefficient is null
