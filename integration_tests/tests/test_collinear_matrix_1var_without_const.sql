with

expected as (

  select 'x1' as variable_name, 30.500076644845674 as coefficient, 0.8396121329329627 as standard_error, 36.326388636502585 as t_statistic

)

select
  coalesce(base.variable_name, expected.variable_name) as variable_name,
  expected.coefficient as expected_coefficient,
  base.coefficient as actual_coefficient
from {{ ref('collinear_matrix_1var_without_const') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where
  abs(base.coefficient - expected.coefficient) > {{ var("_test_precision_collinear_matrix") }}
  or abs(base.standard_error - expected.standard_error) > {{ var("_test_precision_collinear_matrix") }}
  or abs(base.t_statistic - expected.t_statistic) > {{ var("_test_precision_collinear_matrix") }}
  or base.coefficient is null
  or base.standard_error is null
  or base.t_statistic is null
  or expected.coefficient is null
