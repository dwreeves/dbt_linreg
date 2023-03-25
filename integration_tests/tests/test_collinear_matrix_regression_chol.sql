with

expected as (

  select 'const' as variable_name, 19.757104885315176 as coefficient
  union all
  select 'x1' as variable_name, 9.90708767581426 as coefficient
  union all
  select 'x2' as variable_name, 6.187473206056227 as coefficient
  union all
  select 'x3' as variable_name, 19.66874583168642 as coefficient
  union all
  select 'x4' as variable_name, 3.7192417102253468 as coefficient
  union all
  select 'x5' as variable_name, 13.444273483323244 as coefficient

)

select base.variable_name
from {{ ref('collinear_matrix_regression_chol') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where
  round(base.coefficient, 7) - round(expected.coefficient, 7)
  or base.coefficient is null
