select *
from {{ ref('perfectly_multicollinear_model') }}
where
  const is not null
  or xa is not null
  or xb is not null
