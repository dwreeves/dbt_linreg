with

expected as (

  select 'x1' as variable_name, 63.18154691334764 as coefficient, 0.4056389914380657 as standard_error, 155.75807120848344 as t_statistic
  union all
  select 'x2' as variable_name, 55.39820150046505 as coefficient, 0.2738669097295638 as standard_error, 202.2814715190283 as t_statistic

)

select base.variable_name
from {{ ref('collinear_matrix_2var_without_const') }} as base
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
