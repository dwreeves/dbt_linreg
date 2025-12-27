with

expected as (

  select 'x1' as variable_name, 63.18154691334764 as coefficient, 0.4056389914380657 as standard_error, 155.75807120848344 as t_statistic
  union all
  select 'x2' as variable_name, 55.39820150046505 as coefficient, 0.2738669097295638 as standard_error, 202.2814715190283 as t_statistic

)

select
  coalesce(base.variable_name, expected.variable_name) as variable_name,
  expected.coefficient as expected_coefficient,
  base.coefficient as actual_coefficient
from {{ ref('collinear_matrix_2var_without_const') }} as base
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
