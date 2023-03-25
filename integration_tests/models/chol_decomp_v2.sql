{{
  config(
    materialized="table",
    tags=["perftest"]
  )
}}
{#{%- set exog_aliased = ['x1', 'x2', 'x3', 'x4'] %}#}
{%- set exog_aliased = ['x1', 'x2', 'x3', 'x4', 'x5', 'x6', 'x7', 'x8', 'x9'] %}
with base as (

  select
    y,
    1 as x0,
    xa as x1,
    xb as x2,
    xc as x3,
    xd as x4,
    xe as x5,
    xf as x6,
    xg as x7,
    xh as x8,
    xi as x9,
    xj as x10
  from {{ ref('simple_matrix') }}

),

xtx as (

  select
    {%- for i, j in modules.itertools.combinations_with_replacement(range(exog_aliased|length), 2) %}
    sum(x{{ i }} * x{{ j }}) as x{{ i }}x{{ j }}
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from base

),

chol as (

  select
    *,
    (x0x8)/i0j0 as i8j0,
    (x1x8-i8j0*i1j0)/i1j1 as i8j1,
    (x2x8-i8j0*i2j0-i8j1*i2j1)/i2j2 as i8j2,
    (x3x8-i8j0*i3j0-i8j1*i3j1-i8j2*i3j2)/i3j3 as i8j3,
    (x4x8-i8j0*i4j0-i8j1*i4j1-i8j2*i4j2-i8j3*i4j3)/i4j4 as i8j4,
    (x5x8-i8j0*i5j0-i8j1*i5j1-i8j2*i5j2-i8j3*i5j3-i8j4*i5j4)/i5j5 as i8j5,
    (x6x8-i8j0*i6j0-i8j1*i6j1-i8j2*i6j2-i8j3*i6j3-i8j4*i6j4-i8j5*i6j5)/i6j6 as i8j6,
    (x7x8-i8j0*i7j0-i8j1*i7j1-i8j2*i7j2-i8j3*i7j3-i8j4*i7j4-i8j5*i7j5-i8j6*i7j6)/i7j7 as i8j7,
    sqrt(x8x8-i8j0*i8j0-i8j1*i8j1-i8j2*i8j2-i8j3*i8j3-i8j4*i8j4-i8j5*i8j5-i8j6*i8j6-i8j7*i8j7) as i8j8
  from
  (select *,
    (x0x7)/i0j0 as i7j0,
    (x1x7-i7j0*i1j0)/i1j1 as i7j1,
    (x2x7-i7j0*i2j0-i7j1*i2j1)/i2j2 as i7j2,
    (x3x7-i7j0*i3j0-i7j1*i3j1-i7j2*i3j2)/i3j3 as i7j3,
    (x4x7-i7j0*i4j0-i7j1*i4j1-i7j2*i4j2-i7j3*i4j3)/i4j4 as i7j4,
    (x5x7-i7j0*i5j0-i7j1*i5j1-i7j2*i5j2-i7j3*i5j3-i7j4*i5j4)/i5j5 as i7j5,
    (x6x7-i7j0*i6j0-i7j1*i6j1-i7j2*i6j2-i7j3*i6j3-i7j4*i6j4-i7j5*i6j5)/i6j6 as i7j6,
    sqrt(x7x7-i7j0*i7j0-i7j1*i7j1-i7j2*i7j2-i7j3*i7j3-i7j4*i7j4-i7j5*i7j5-i7j6*i7j6) as i7j7
  from
  (select *,
    (x0x6)/i0j0 as i6j0,
    (x1x6-i6j0*i1j0)/i1j1 as i6j1,
    (x2x6-i6j0*i2j0-i6j1*i2j1)/i2j2 as i6j2,
    (x3x6-i6j0*i3j0-i6j1*i3j1-i6j2*i3j2)/i3j3 as i6j3,
    (x4x6-i6j0*i4j0-i6j1*i4j1-i6j2*i4j2-i6j3*i4j3)/i4j4 as i6j4,
    (x5x6-i6j0*i5j0-i6j1*i5j1-i6j2*i5j2-i6j3*i5j3-i6j4*i5j4)/i5j5 as i6j5,
    sqrt(x6x6-i6j0*i6j0-i6j1*i6j1-i6j2*i6j2-i6j3*i6j3-i6j4*i6j4-i6j5*i6j5) as i6j6
  from
  (select *,
    (x0x5)/i0j0 as i5j0,
    (x1x5-i5j0*i1j0)/i1j1 as i5j1,
    (x2x5-i5j0*i2j0-i5j1*i2j1)/i2j2 as i5j2,
    (x3x5-i5j0*i3j0-i5j1*i3j1-i5j2*i3j2)/i3j3 as i5j3,
    (x4x5-i5j0*i4j0-i5j1*i4j1-i5j2*i4j2-i5j3*i4j3)/i4j4 as i5j4,
    sqrt(x5x5-i5j0*i5j0-i5j1*i5j1-i5j2*i5j2-i5j3*i5j3-i5j4*i5j4) as i5j5,
  from
  (select *,
    (x0x4)/i0j0 as i4j0,
    (x1x4-i4j0*i1j0)/i1j1 as i4j1,
    (x2x4-i4j0*i2j0-i4j1*i2j1)/i2j2 as i4j2,
    (x3x4-i4j0*i3j0-i4j1*i3j1-i4j2*i3j2)/i3j3 as i4j3,
    sqrt(x4x4-i4j0*i4j0-i4j1*i4j1-i4j2*i4j2-i4j3*i4j3) as i4j4
  from
  (select *,
    (x0x3)/i0j0 as i3j0,
    (x1x3-i3j0*i1j0)/i1j1 as i3j1,
    (x2x3-i3j0*i2j0-i3j1*i2j1)/i2j2 as i3j2,
    sqrt(x3x3-i3j0*i3j0-i3j1*i3j1-i3j2*i3j2) as i3j3
  from
  (select *,
    (x0x2)/i0j0 as i2j0,
    (x1x2-i2j0*i1j0)/i1j1 as i2j1,
    sqrt(x2x2-i2j0*i2j0-i2j1*i2j1) as i2j2,
  from
  (select
    *,
    sqrt(x0x0) as i0j0,
    (x0x1)/i0j0 as i1j0,
    sqrt(x1x1-i1j0*i1j0) as i1j1
  from xtx)))))))

),

inverse_chol as (

  select
    *,
    (1/i7j7) as inv_i7j7,
    ((-i8j7*inv_i7j7)/i8j8) as inv_i7j8,
    (1/i8j8) as inv_i8j8
  from (
  select *,
    (1/i6j6) as inv_i6j6,
    ((-i7j6*inv_i6j6)/i7j7) as inv_i6j7,
    ((-i8j6*inv_i6j6-i8j7*inv_i6j7)/i8j8) as inv_i6j8,
  from (
  select *,
    (1/i5j5) as inv_i5j5,
    ((-i6j5*inv_i5j5)/i6j6) as inv_i5j6,
    ((-i7j5*inv_i5j5-i7j6*inv_i5j6)/i7j7) as inv_i5j7,
    ((-i8j5*inv_i5j5-i8j6*inv_i5j6-i8j7*inv_i5j7)/i8j8) as inv_i5j8,
  from (
  select *,
    (1/i4j4) as inv_i4j4,
    ((-i5j4*inv_i4j4)/i5j5) as inv_i4j5,
    ((-i6j4*inv_i4j4-i6j5*inv_i4j5)/i6j6) as inv_i4j6,
    ((-i7j4*inv_i4j4-i7j5*inv_i4j5-i7j6*inv_i4j6)/i7j7) as inv_i4j7,
    ((-i8j4*inv_i4j4-i8j5*inv_i4j5-i8j6*inv_i4j6-i8j7*inv_i4j7)/i8j8) as inv_i4j8,
  from (
  select *,
    (1/i3j3) as inv_i3j3,
    ((-i4j3*inv_i3j3)/i4j4) as inv_i3j4,
    ((-i5j3*inv_i3j3-i5j4*inv_i3j4)/i5j5) as inv_i3j5,
    ((-i6j3*inv_i3j3-i6j4*inv_i3j4-i6j5*inv_i3j5)/i6j6) as inv_i3j6,
    ((-i7j3*inv_i3j3-i7j4*inv_i3j4-i7j5*inv_i3j5-i7j6*inv_i3j6)/i7j7) as inv_i3j7,
    ((-i8j3*inv_i3j3-i8j4*inv_i3j4-i8j5*inv_i3j5-i8j6*inv_i3j6-i8j7*inv_i3j7)/i8j8) as inv_i3j8,
  from (
  select *,
    (1/i2j2) as inv_i2j2,
    ((-i3j2*inv_i2j2)/i3j3) as inv_i2j3,
    ((-i4j2*inv_i2j2-i4j3*inv_i2j3)/i4j4) as inv_i2j4,
    ((-i5j2*inv_i2j2-i5j3*inv_i2j3-i5j4*inv_i2j4)/i5j5) as inv_i2j5,
    ((-i6j2*inv_i2j2-i6j3*inv_i2j3-i6j4*inv_i2j4-i6j5*inv_i2j5)/i6j6) as inv_i2j6,
    ((-i7j2*inv_i2j2-i7j3*inv_i2j3-i7j4*inv_i2j4-i7j5*inv_i2j5-i7j6*inv_i2j6)/i7j7) as inv_i2j7,
    ((-i8j2*inv_i2j2-i8j3*inv_i2j3-i8j4*inv_i2j4-i8j5*inv_i2j5-i8j6*inv_i2j6-i8j7*inv_i2j7)/i8j8) as inv_i2j8,
  from (
  select *,
    (1/i1j1) as inv_i1j1,
    ((-i2j1*inv_i1j1)/i2j2) as inv_i1j2,
    ((-i3j1*inv_i1j1-i3j2*inv_i1j2)/i3j3) as inv_i1j3,
    ((-i4j1*inv_i1j1-i4j2*inv_i1j2-i4j3*inv_i1j3)/i4j4) as inv_i1j4,
    ((-i5j1*inv_i1j1-i5j2*inv_i1j2-i5j3*inv_i1j3-i5j4*inv_i1j4)/i5j5) as inv_i1j5,
    ((-i6j1*inv_i1j1-i6j2*inv_i1j2-i6j3*inv_i1j3-i6j4*inv_i1j4-i6j5*inv_i1j5)/i6j6) as inv_i1j6,
    ((-i7j1*inv_i1j1-i7j2*inv_i1j2-i7j3*inv_i1j3-i7j4*inv_i1j4-i7j5*inv_i1j5-i7j6*inv_i1j6)/i7j7) as inv_i1j7,
    ((-i8j1*inv_i1j1-i8j2*inv_i1j2-i8j3*inv_i1j3-i8j4*inv_i1j4-i8j5*inv_i1j5-i8j6*inv_i1j6-i8j7*inv_i1j7)/i8j8) as inv_i1j8,
  from (
  select *,
    (1/i0j0) as inv_i0j0,
    ((-i1j0*inv_i0j0)/i1j1) as inv_i0j1,
    ((-i2j0*inv_i0j0-i2j1*inv_i0j1)/i2j2) as inv_i0j2,
    ((-i3j0*inv_i0j0-i3j1*inv_i0j1-i3j2*inv_i0j2)/i3j3) as inv_i0j3,
    ((-i4j0*inv_i0j0-i4j1*inv_i0j1-i4j2*inv_i0j2-i4j3*inv_i0j3)/i4j4) as inv_i0j4,
    ((-i5j0*inv_i0j0-i5j1*inv_i0j1-i5j2*inv_i0j2-i5j3*inv_i0j3-i5j4*inv_i0j4)/i5j5) as inv_i0j5,
    ((-i6j0*inv_i0j0-i6j1*inv_i0j1-i6j2*inv_i0j2-i6j3*inv_i0j3-i6j4*inv_i0j4-i6j5*inv_i0j5)/i6j6) as inv_i0j6,
    ((-i7j0*inv_i0j0-i7j1*inv_i0j1-i7j2*inv_i0j2-i7j3*inv_i0j3-i7j4*inv_i0j4-i7j5*inv_i0j5-i7j6*inv_i0j6)/i7j7) as inv_i0j7,
    ((-i8j0*inv_i0j0-i8j1*inv_i0j1-i8j2*inv_i0j2-i8j3*inv_i0j3-i8j4*inv_i0j4-i8j5*inv_i0j5-i8j6*inv_i0j6-i8j7*inv_i0j7)/i8j8) as inv_i0j8,
  from chol
  )))))))
),

inverse_xtx as (

  select
    {%- for i, j in modules.itertools.combinations_with_replacement(range((exog_aliased | length)), 2) %}
    {%- for k in range(j, (exog_aliased | length)) %}
    inv_i{{ i }}j{{ k }} * inv_i{{ j }}j{{ k }}
    {%- if not loop.last %} + {% endif -%}
    {%- endfor %}
    as inv_x{{ i }}x{{ j }}
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from inverse_chol

),

linreg as (

  select
    {%- for x1 in range(exog_aliased|length) %}
    sum((
    {%- for x2 in range(exog_aliased|length) %}
      {%- if x2 > x1 %}
      x{{ x2 }} * inv_x{{ x1 }}x{{ x2 }}
      {%- else %}
      x{{ x2 }} * inv_x{{ x2 }}x{{ x1 }}
      {%- endif %}
      {%- if not loop.last %} + {% endif -%}
    {%- endfor %}
    ) * y) as x{{ x1 }}_coef
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from
    base,
    inverse_xtx

)

select * from linreg
