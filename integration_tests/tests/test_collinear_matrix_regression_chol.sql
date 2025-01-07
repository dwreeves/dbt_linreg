with

expected as (

  select 'const' as variable_name, 19.757104885315176 as coefficient, 2.992803142237603 as standard_error, 6.601538406078909 as t_statistic
  union all
  select 'x1' as variable_name, 9.90708767581426 as coefficient, 0.5692826957191374 as standard_error, 17.402755696445837 as t_statistic
  union all
  select 'x2' as variable_name, 6.187473206056227 as coefficient, 1.0880807259333622 as standard_error, 5.686593888287631 as t_statistic
  union all
  select 'x3' as variable_name, 19.66874583168642 as coefficient, 0.5601379212447676 as standard_error, 35.11411223146169 as t_statistic
  union all
  select 'x4' as variable_name, 3.7192417102253468 as coefficient, 0.15560940177101745 as standard_error, 23.901137514160553 as t_statistic
  union all
  select 'x5' as variable_name, 13.444273483323244 as coefficient, 0.5121595119107619 as standard_error, 26.250168493728488 as t_statistic

)

select
  coalesce(base.variable_name, expected.variable_name) as variable_name,
  expected.coefficient as expected_coefficient,
  base.coefficient as actual_coefficient,
  expected.standard_error as expected_standard_error,
  base.standard_error as actual_standard_error,
  expected.t_statistic as expected_t_statistic,
  base.t_statistic as actual_t_statistic
from {{ ref('collinear_matrix_regression_chol') }} as base
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
