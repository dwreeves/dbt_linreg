<p align="center">
    <picture>
        <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/dwreeves/dbt_linreg/main/docs/src/img/dbt-linreg-banner-dark.png#readme-logo">
        <img src="https://raw.githubusercontent.com/dwreeves/dbt_linreg/main/docs/src/img/dbt-linreg-banner-light.png#readme-logo" alt="dbt_linreg logo">
    </picture>
</p>
<p align="center">
    <em>Linear regression in any SQL dialect, powered by dbt.</em>
</p>
<p align="center">
    <img src="https://github.com/dwreeves/dbt_linreg/workflows/tests/badge.svg" alt="Tests badge">
    <img src="https://github.com/dwreeves/dbt_linreg/workflows/docs/badge.svg" alt="Docs badge">
</p>

# Overview

**dbt_linreg** is an easy way to perform linear regression and ridge regression in SQL (Snowflake, DuckDB, Clickhouse, and more) with OLS using dbt's Jinja2 templating.

Reasons to use **dbt_linreg**:

- 📈 **Linear regression in pure SQL:** With the power of Jinja2 templating and some behind-the-scenes math tricks, it is possible to implement multiple and multivariate regression in pure SQL. Most SQL engines (even OLAP engines) do not have a multiple regression implementation of OLS, so this fills a valuable niche. **`dbt_linreg` implements true OLS, not an approximation!**
- 📱 **Simple interface:** Just define a `table=` (which works with `ref()`, `source()`, and CTEs), a y-variable with `endog=`, your x-variables in a list with `exog=...`, and you're all set! Note that the API is loosely based on Statsmodels's naming conventions.
- 🤖 **Support for ridge regression:** Just pass in `alpha=scalar` or `alpha=[scalar1, scalar2, ...]` to regularize your regressions. (Note: regressors are not automatically standardized.)
- 🤸‍ **Flexibility:** Tons of formatting options available to return coefficients the way you want.
- 🤗 **User friendly:** The API provides comprehensive feedback on input errors.
- 💪 **Durable and tested:** Everything in this code base is tested against equivalent regressions performed in Statsmodels with high precision assertions (between 10e-6 to 10e-7, depending on the database engine).

_Note: If you enjoy this project, you may also enjoy my other dbt machine learning project, [**dbt_pca**](https://github.com/dwreeves/dbt_pca)._ 😊

# Installation

dbt-core `>=1.2.0` is required to install `dbt_linreg`.

Add this the `packages:` list your dbt project's `packages.yml`:

```yaml
  - package: "dwreeves/dbt_linreg"
    version: "0.3.1"
```

The full file will look something like this:

```yaml
packages:
  # ...
  # Other packages here
  # ...
  - package: "dwreeves/dbt_linreg"
    version: "0.3.1"
```

# Examples

### Simple example

The following example runs a linear regression of 3 columns `xa + xb + xc` on `y`, using data in the dbt model named `simple_matrix`. It outputs the data in "long" format, and rounds the coefficients to 5 decimal points:

```sql
{{
  config(
    materialized="table"
  )
}}
select * from {{
  dbt_linreg.ols(
    table=ref('simple_matrix'),
    endog='y',
    exog=['xa', 'xb', 'xc'],
    output='long',
    output_options={'round': 5}
  )
}} as linreg
```

Output:

|variable_name|coefficient|standard_error|t_statistic|
|---|---|---|---|
|const|10.0|0.00462|2163.27883|
|xa|5.0|0.46226|10.81639|
|xb|7.0|0.46226|15.14295|
|xc|9.0|0.46226|19.46951|

Note: `simple_matrix` is one of the test cases, so you can try this yourself! Standard errors are constant across `xa`, `xb`, `xc`, because `simple_matrix` is orthonormal.

### Complex example

The following hypothetical example shows multiple ridge regressions (one per `product_id`) on a table that is preprocessed substantially. After the fact, predictions are run, and the R-squared of each regression is calculated at the end.

This example shows that, although `dbt_linreg` does not implement everything for you, the OLS implementation does most of the hard work. This gives you the freedom to do things you've never been able to do before in SQL!

```sql
{{
  config(
    materialized="table"
  )
}}
with

preprocessed_data as (

  select
    product_id,
    price,
    log(price) as log_price,
    epoch(time) as t,
    sin(epoch(time)*pi()*2 / (60*60*24*365)) as sin_t,
    cos(epoch(time)*pi()*2 / (60*60*24*365)) as cos_t
  from
    {{ ref('prices') }}

),

preprocessed_and_normalized_data as (

  select
    product_id,
    price,
    log(price) as log_price,
    (time - avg(time) over ()) / (stddev(time) over ()) as t_norm,
    (sin_t - avg(sin_t) over ()) / (stddev(sin_t) over ()) as sin_t_norm,
    (cos_t - avg(cos_t) over ()) / (stddev(cos_t) over ()) as cos_t_norm
  from
    preprocessed_data

),

coefficients as (

    select * from {{
      dbt_linreg.ols(
        table='preprocessed_and_normalized_data',
        endog='log_price',
        exog=['t_norm', 'sin_t_norm', 'cos_t_norm'],
        group_by=['product_id'],
        alpha=0.0001
      )
    }}

),

predict as (

  select
    d.product_id,
    d.time,
    d.price,
    exp(
      c.const
      + d.t_norm * c.t_norm
      + d.sin_t_norm * c.sin_t_norm
      + d.cos_t_norm * sin_t_norm) as predicted_price
  from
    preprocessed_and_normalized_data as d
  join
    coefficients as c
  on
    d.product_id = c.product_id

)

select
  product_id,
  pow(corr(predicted_price, price), 2) as r_squared
from
  predict
group by
  product_id
```

# Supported Databases

**dbt_linreg** should work with most SQL databases, but so far, testing has been done for the following database tools:

| Database       | Supported | Precision asserted in CI\* | Supported since version |
|----------------|-----------|----------------------------|-------------------------|
| **Snowflake**  | ✅         | _n/a_                      | 0.1.0                   |
| **DuckDB**     | ✅         | 10e-7                      | 0.1.0                   |
| **Postgres**†  | ✅         | 10e-7                      | 0.2.3                   |
| **Redshift**   | ✅         | _n/a_                      | 0.2.4                   |
| **Clickhouse** | ✅         | 10e-6                      | 0.3.0                   |

If **dbt_linreg** does not work in your database tool, please let me know in a bug report.

> _\* Precision is for test cases using the **collinear_matrix** for unregularized regressions, in comparison to the output of the same regression in the Python package Statsmodels using `sm.OLS().fit(method="pinv")`. For example, coefficients for unregularized regressions performed in DuckDB are asserted to be within 10e-7 of Statsmodels._

> _† Minimal support for Postgres. Postgres is syntactically supported, but is not performant under certain circumstances._

# API

The only function available in the public API is the `dbt_linreg.ols()` macro.

Using Python typing notation, the full API for `dbt_linreg.ols()` looks like this:

```python
def ols(
    table: str,
    endog: str,
    exog: Union[str, list[str]],
    add_constant: bool = True,
    output: Literal['wide', 'long'] = 'wide',
    output_options: Optional[dict[str, Any]] = None,
    group_by: Optional[Union[str, list[str]]] = None,
    alpha: Optional[Union[float, list[float]]] = None,
    method: Literal['chol', 'fwl'] = 'chol',
    method_options: Optional[dict[str, Any]] = None
):
    ...
```

Where:

- **table**: Name of table or CTE to pull the data from. You can use `ref()` or `source()` here if you'd like.
- **endog**: The endogenous variable / y variable / target variable of the regression. (You can also specify `y=...` instead of `endog=...` if you prefer.)
- **exog**: The exogenous variables / X variables / features of the regression. (You can also specify `x=...` instead of `exog=...` if you prefer.)
- **add_constant**: If true, a constant term is added automatically to the regression.
- **output**: Either "wide" or "long" output format for coefficients. See **Outputs and output options** for more.
  - If `wide`, the variables span the columns with their original variable names, and the coefficients fill a single row.
  - If `long`, the coefficients are in a single column called `coefficient`, and the variable names are in a single column called `variable_name`.
- **output_options**: See **Formats and format options** section for more.
- **group_by**: If specified, the regression will be grouped by these variables, and individual regressions will run on each group.
- **alpha**: If not null, the regression will be run as a ridge regression with a penalty of `alpha`. See **Notes** section for more information.
- **method**: The method used to calculate the regression. See **Methods and method options** for more.
- **method_options**: Options specific to the estimation method. See **Methods and method options** for more.

# Outputs and output options

Outputs can be returned either in `output='long'` or `output='wide'`.

All outputs have their own output options, which can be passed into the `output_options=` arg as a dict, e.g. `output_options={'foo': 'bar'}`.

`output=` and `output_options=` were formerly named `format=` and `format_options=` respectively.
This has been deprecated to make **dbt_linreg**'s API more consistent with **dbt_pca**'s API.

### Options for `output='long'`

- **round** (`int`; default = `None`): If not None, round all coefficients to `round` number of digits.
- **constant_name** (`string`; default = `'const'`): String name that refers to constant term.
- **variable_column_name** (`string`; default = `'variable_name'`): Column name storing strings of variable names.
- **coefficient_column_name** (`string`; default = `'coefficient'`): Column name storing model coefficients.
- **strip_quotes** (`bool`; default = `True`): If true, strip outer quotes from column names if provided; if false, always use string literals.

These options are available for `output='long'` only when `method='chol'`:

- **calculate_standard_error** (`bool`; default = `True if not alpha else False`): If true, provide the standard error in the output.
- **standard_error_column_name** (`string`; default = `'standard_error'`): Column name storing the standard error for the parameter.
- **t_statistic_column_name** (`string`; default = `'t_statistic'`): Column name storing the t-statistic for the parameter.

### Options for `output='wide'`

- **round** (`int`; default = `None`): If not None, round all coefficients to `round` number of digits.
- **constant_name** (`string`; default = `'const'`): String name that refers to constant term.
- **variable_column_prefix** (`string`; default = `None`): If not None, prefix all variable columns with this. (Does NOT delimit, so make sure to include your own underscore if you'd want that.)
- **variable_column_suffix** (`string`; default = `None`): If not None, suffix all variable columns with this. (Does NOT delimit, so make sure to include your own underscore if you'd want that.)

## Setting output options globally

Output options can be set globally via `vars`, e.g. in your `dbt_project.yml`:

```yaml
# dbt_project.yml
vars:
  dbt_linreg:
    output_options:
      round: 5
```

Output options passed via `ols()` always take precedence over globally set output options.

# Methods and method options

There are currently two valid methods for calculating regression coefficients:

- `chol`: Uses Cholesky decomposition to calculate the pseudo-inverse.
- `fwl`: Uses a "Frisch-Waugh-Lovell" approach, which consists of calculating univariate regressions to get multiple regression coefficients.

## `chol` method

**👍 This is the suggested method (and the default) for calculating regressions!**

This method calculates regression coefficients using the Moore-Penrose pseudo-inverse, and the inverse of **X'X** is calculated using Cholesky decomposition, hence it is referred to as `chol`.

### Options for `method='chol'`

Specify these in a dict using the `method_options=` kwarg:

- **safe** (`bool`; default: `True`): If True, returns null coefficients instead of an error when X is perfectly multicollinear. If False, a negative value may be passed into a SQRT() or a divide by zero may occur, and most SQL engines will raise an error when this happens.
- **subquery_optimization** (`bool`; default = `True`): If True, nested subqueries are used during some of the steps to optimize the query speed. If false, the query is flattened.
- **intra_select_aliasing** (`bool`; default = `[depends on db]`): If True, within a single select statement, column aliases are used to refer to other columns created during that select. This can significantly reduce the text of a SQL query, but not all SQL engines support this. By default, for all databases officially supported by **dbt_linreg**, the best option is already selected. For unsupported databases, the default is `False` for broad compatibility, so if you are running **dbt_linreg** in an officially unsupported database engine which supports this feature, you may want to modify this option globally in your `vars` to be `true`.

## `fwl` method

**This method is generally not recommended.**

Simple univariate regression coefficients are simply `covar_pop(y, x) / var_pop(x)`.

The multiple regression implementation uses a technique described in section `3.2.3 Multiple Regression from Simple Univariate Regression` of TEoSL ([source](https://hastie.su.domains/Papers/ESLII.pdf#page=71)). Econometricians know this as the Frisch-Waugh-Lovell theorem, hence the method is referred to as `fwl` internally in the code base.

Ridge regression is implemented using the augmentation technique described in Exercise 12 of Chapter 3 of TEoSL ([source](https://hastie.su.domains/Papers/ESLII.pdf#page=115)).

There are a few reasons why this method is discouraged over the `chol` method:

- 🐌 It tends to be much slower in OLAP systems, and struggles to efficiently calculate large number of columns.
- 📊 It does not calculate standard errors.
- 😕 For ridge regression, coefficients are not accurate; they tend to be off by a magnitude of ~0.01%.
- ⚠️ It does not work in all databases because it relies on `COVAR_POP`.

So when should you use `fwl`? The main use case is in OLTP systems (e.g. Postgres) for unregularized coefficient estimation. Long story short, the `chol` method relies on subquery optimization to be more performant than `fwl`; however, OLTP systems do not benefit at all from subquery optimization. This means that `fwl` is slightly more performant in this context.

## Setting method options globally

Method options can be set globally via `vars`, e.g. in your `dbt_project.yml`. Each `method` gets its own config, e.g. the `dbt_linreg: method_options: chol: ...` namespace only applies to the `chol` method. Here is an example:

```yaml
# dbt_project.yml
vars:
  dbt_linreg:
    method_options:
      chol:
        intra_select_aliasing: true
```

Method options passed via `ols()` always take precedence over globally set method options.

# Notes

- ⚠️ **If your coefficients are null, it does not mean dbt_linreg is broken, it most likely means your feature columns are perfectly multicollinear.** If you are 100% sure that is not the issue, please file a bug report with a minimally reproducible example.

- Regularization is implemented using nearly the same approach as Statsmodels; the only difference is that the constant term can never be regularized. This means:
  - A scalar input (e.g. `alpha=0.01`) will apply an alpha of `0.01` to all features.
  - An array input (e.g. `alpha=[0.01, 0.02, 0.03, 0.04, 0.05]`) will apply an alpha of `0.01` to the first column, `0.02` to the second column, etc.
  - `alpha` is equivalent to what TEoSL refers to as "lambda," times the sample size N. That is to say: `α ≡ λ * N`.
  - (Of course, you can regularize the constant term by DIYing your own constant term and doing `add_constant=false`.)

- Regularization as currently implemented for the `chol` method tends to be very slow in OLTP systems (e.g. Postgres), but is very performant in OLAP systems (e.g. Snowflake, DuckDB, BigQuery, Redshift). As dbt is more commonly used in OLAP contexts, the code base is optimized for the OLAP use case.
  - That said, it may be possible to make regularization in OLTP more performant (e.g. with augmentation of the design matrix), so PRs are welcome.

- Regression coefficients in Postgres are always `numeric` types.

## Possible future features

Some things that could happen in the future:

- Weighted least squares (WLS)
- Efficient multivariate regression (i.e. multiple endogenous vectors sharing a single design matrix)
- P-values
- Heteroskedasticity robust standard errors
- Recursive CTE implementations + long formatted inputs

Note that although I maintain this library (as of writing in 2025), I do not actively update it much with new features, so this wish list is unlikely unless I personally need it or unless someone else contributes these features.

# FAQ

### How does this work?

See **Methods and method options** section for a full breakdown of each linear regression implementation.

All approaches were validated using Statsmodels `sm.OLS()`.

### BigQuery (or other database) has linear regression implemented natively. Why should I use `dbt_linreg` over that?

You don't have to use this. Most warehouses don't support multiple regression out of the box, so this satisfies a niche for those database tools which don't.

That said, even in BigQuery, it may be very useful to extract coefficients within a query instead of generating a separate `MODEL` object through a DDL statement, for a few reasons. Even in more black box predictive contexts, being able to predict in the same `SELECT` statement as training can be convenient. Additionally, BigQuery does not expose model coefficients to users, and this can be a dealbreaker in many contexts where you care about your coefficients as measurements, not as predictive model parameters. Lastly, `group_by` is akin to estimating parameters for multiple linear regressions at once.

Overall, I would say this is pretty different from what BigQuery's `CREATE MODEL` is doing; use whatever makes sense for your use case! But keep in mind that for large numbers of variables, a native implementation of linear regression will be noticeably more efficient than this implementation.

### Why is L2 regularization / ridge regression supported, but not L1 regularization / LASSO supported?

There is no closed-form solution to L1 regularization, which makes it very very hard to add through raw SQL. L2 regularization has a closed-form solution and can be implemented using a pre-processing trick.

### Is the `group_by=[...]` argument like categorical variables / one-hot encodings?

No. The `group_by` runs a linear regressions within each group, and each individual partition is its own `y` vector and `X` matrix. This is _not_ a replacement for dummy variables.

### Why aren't categorical variables / one-hot encodings supported?

I opt to leave out dummy variable support because it's tricky, and I want to keep the API clean and mull on how to best implement that at the highest level.

Note that you couldn't simply add categorical variables in the same list as numeric variables because Jinja2 templating is not natively aware of the types you're feeding through it, nor does Jinja2 know the values that a string variable can take on. The way you would actually implement categorical variables is with `group by` trickery (i.e. center both y and X by categorical variable group means), although I am not sure how to do that efficiently for more than one categorical variable column.

If you'd like to regress on a categorical variable, for now you'll need to do your own feature engineering, e.g. `(foo = 'bar')::int as foo_bar, (foo = 'baz')::int as foo_baz`.

### Why are there no p-values?

This is something that might happen in the future. P-values would require a lookup on a dimension table, which is a significant amount of work to manage nicely.

In the meanwhile, you can implement this yourself-- just create a dimension table that left joins a t-statistic on a half-open interval to lookup a p-value.

# Trademark & Copyright

dbt is a trademark of dbt Labs.

This package is **unaffiliated** with dbt Labs.
