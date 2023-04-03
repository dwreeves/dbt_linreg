with

expected as (

  select 'x1' as variable_name, 20.090207982897063 as coefficient, 0.5196176972417176 as standard_error, 38.6634406209445 as t_statistic
  union all
  select 'x2' as variable_name, -16.533211090826203 as coefficient, 0.7481701784700665 as standard_error, -22.098195793682894 as t_statistic
  union all
  select 'x3' as variable_name, 35.00389104686492 as coefficient, 0.351617515124373 as standard_error, 99.55104493154575 as t_statistic

)

select base.variable_name
from {{ ref('collinear_matrix_3var_without_const') }} as base
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
