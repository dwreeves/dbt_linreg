with

expected as (

  select 'x1' as variable_name, 20.587532776354163 as coefficient, 0.5176259827853541 as standard_error, 39.772989496339235 as t_statistic
  union all
  select 'x2' as variable_name, -20.41001520357013 as coefficient, 0.8103907603637923 as standard_error, -25.185399688426696 as t_statistic
  union all
  select 'x3' as variable_name, 35.084935774341524 as coefficient, 0.34920588221192245 as standard_error, 100.4706322588505 as t_statistic
  union all
  select 'x4' as variable_name, 1.8960558858899716 as coefficient, 0.1583538085466205 as standard_error, 11.973541421529871 as t_statistic

)

select base.variable_name
from {{ ref('collinear_matrix_4var_without_const') }} as base
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
