
<p align="center">
    <img src="https://raw.githubusercontent.com/dwreeves/dbt_linreg/main/docs/src/img/dbt-linreg-banner.png" alt="dbt_linreg logo">
</p>
<p align="center">
    <em>Linear regression in any SQL dialect, powered by dbt.</em>
</p>
<p align="center">
    <img src="https://github.com/dwreeves/dbt_linreg/workflows/tests/badge.svg" alt="Tests badge">
    <img src="https://github.com/dwreeves/dbt_linreg/workflows/docs/badge.svg" alt="Docs badge">
</p>

# Overview

**dbt_linreg** is an easy way to perform linear regression and ridge regression in SQL (Snowflake, DuckDB, and more) with OLS using dbt's Jinja2 templating.

Reasons to use **dbt_linreg**:

- 📈 **Linear regression in pure SQL:** With the power of Jinja2 templating and some behind-the-scenes math tricks, it is possible to implement multiple and multivariate regression in pure SQL. Most SQL engines (even OLAP engines) do not have a multiple regression implementation of OLS, so this fills a valuable niche. **`dbt_linreg` implements true OLS, not an approximation!**
- 📱 **Simple interface:** Just define a `table=` (which works with `ref()`, `source()`, and CTEs), a y-variable with `endog=`, your x-variables in a list with `exog=...`, and you're all set! Note that the API is loosely based on Statsmodels's naming conventions.
- 🤖 **Support for ridge regression:** Just pass in `alpha=scalar` or `alpha=[scalar1, scalar2, ...]` to regularize your regressions. (Note: regressors are not automatically standardized.)
- 🤸‍ **Flexibility:** Tons of formatting options available to return coefficients the way you want.
- 💪 **Durable and tested:** The API provides feedback on parsing errors, and everything in this code base has been tested (check the continuous integration).

# Installation

dbt-core `>=1.2.0` is required to install `dbt_linreg`.

Add this the `packages:` list your dbt project's `packages.yml`:

```yaml
  - git: "https://github.com/dwreeves/dbt_linreg.git"
    revision: "v0.1.1"
```

The full file will look something like this:

```yaml
packages:
  # ...
  # Other packages here
  # ...
  - git: "https://github.com/dwreeves/dbt_linreg.git"
    revision: "v0.1.1"
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
    table=ref('simple_matrix')
    endog='y',
    exog=['xa', 'xb', 'xc'],
    format='long',
    format_options={'round': 5}
  )
}}
```

Output:

|variable_name|coefficient|
|---|---|
|const|10.0|
|xa|3.0|
|xb|5.0|
|xc|7.0|

Note: `simple_matrix` is one of the test cases.

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

# API

The only function available in the public API is the `dbt_linreg.ols()` macro.

Using Python typing notation, the full API for `dbt_linreg.ols()` looks like this:

```python
def ols(
    table: str,
    endog: str,
    exog: Union[str, list[str]],
    format: Literal['wide', 'long'] = 'wide',
    format_options: Optional[dict[str, Any]] = None,
    group_by: Optional[Union[str, list[str]]] = None,
    alpha: Optional[Union[float, list[float]]] = None,
    method: Literal['fwl'] = 'fwl'
):
    ...
```

Where:

- **table**: Name of table or CTE to pull the data from. You can use `ref()` or `source()` here if you'd like.
- **endog**: The endogenous variable / y variable / target variable of the regression. (You can also specify `y=...` instead of `endog=...` if you prefer.)
- **exog**: The endogenous variable / y variable / target variable of the regression. (You can also specify `x=...` instead of `exog=...` if you prefer.)
- **format**: Either "wide" or "long" format for coefficients.
  - If `wide`, the variables span the columns with their original variable names, and the coefficients fill a single row.
  - If `long`, the coefficients are in a single column called `coefficient`, and the variable names are in a single column called `variable_name`.
- **format_options**: See **Formats and format options** section for more.
- **group_by**: If specified, the regression will be grouped by these variables, and individual regressions will run on each group.
- **alpha**: If not null, the regression will be run as a ridge regression with a penalty of `alpha`. See **Notes** section for more information.
- **method**: The way the regression is calculated. Right now, only `'fwl'` is a valid option. See **FAQ** section for implementation details.

# Formats and format options

Outputs can be returned either in `format='long'` or `format='wide'`.

(In the future, I might add one or two more formats, notably a summary table format.)

All formats have their own format options, which can be passed into the `format_options=` arg as a dict, e.g. `format_options={'foo': 'bar'}`.

### Options for `format='long'`

- **round** (default = `None`): If not None, round all coefficients to `round` number of digits.
- **constant_name** (default = `'const'`): String name that refers to constant term.
- **variable_column_name** (default = `'variable_name'`): Column name storing strings of .
- **coefficient_column_name** (default = `'coefficient'`): Column name storing model coefficients.
- **strip_quotes** (default = `True`): If true, strip outer quotes from column names if provided; if false, always use string literals.

### Options for `format='wide'`

- **round** (default = `None`): If not None, round all coefficients to `round` number of digits.
- **constant_name** (default = `'const'`): String name that refers to constant term.
- **variable_column_prefix** (default = `None`): If not None, prefix all variable columns with this. (Does NOT delimit, so make sure to include your own underscore if you'd want that.)
- **variable_column_suffix** (default = `None`): If not None, suffix all variable columns with this. (Does NOT delimit, so make sure to include your own underscore if you'd want that.)

# Notes

- ⚠️ **Please be aware that this implementation is very inefficient for large numbers of columns!** I believe the time complexity of the Jinja templating is O(2^K). I would suggest not going over 5 or 6 features for a single regression.

- ⚠️ **If your coefficients are null, it does not mean dbt_linreg is broken, it most likely means your coefficients are perfectly multicollinear.** If you are 100% sure that is not the issue, please file a bug report with a minimally reproducible example.

- Regularization is implemented using nearly the same approach as Statsmodels; the only difference is that the constant term can never be regularized. This means:
  - A scalar input (e.g. `alpha=0.01`) will apply an alpha of `0.01` to all features.
  - An array input (e.g. `alpha=[0.01, 0.02, 0.03, 0.04, 0.05]`) will apply an alpha of `0.01` to the first column, `0.02` to the second column, etc.
  - `alpha` is equivalent to what TEoSL refers to as "lambda," times the sample size N. That is to say: `α ≡ λ * N`.

- Ridge regression coefficients tend to be slightly off Statsmodels's ridge regression coefficients, but by no more than a 0.01% deviation in my experience (this 0.01% threshold is enforced in the integration tests).

### Possible future features

Some things I am thinking about working on down the line:

- **Optimization:** Given access to Jinja2 templating, there may be more efficient ways to calculate the get a closed form OLS solution than the approach taken in this code base.

- **Standard errors and t-stats:** For the `format='long'` output (or perhaps a new format?), there is space to sensibly add t-stats and standard errors. The main challenge is that this necessitates inverting a covariance matrix, although this is theoretically doable using Jinja2 templating.

# FAQ

### How does this work?

Simple univariate regression coefficients are simply `covar_pop(y, x) / var_pop(x)`.

The multiple regression implementation uses a technique described in section `3.2.3 Multiple Regression from Simple Univariate Regression` of TEoSL ([source](https://hastie.su.domains/Papers/ESLII.pdf#page=71)). Econometricians know this as the Frisch-Waugh-Lowell theorem, hence the method is referred to as `'fwl'` internally in the code base.

Ridge regression is implemented using the augmentation technique described in Exercise 12 of Chapter 3 of TEoSL ([source](https://hastie.su.domains/Papers/ESLII.pdf#page=115)).

All approaches were validated using Statsmodels `sm.OLS()`. Note that the ridge regression coefficients differ very slightly from Statsmodels's outputs for currently unknown reasons, but the coefficients are very close (I enforce a `<0.01%` deviation from Statsmodels's ridge regression coefficients in my integration tests).

### BigQuery (or other database) has linear regression implemented natively. Why should I use `dbt_linreg` over that?

You don't have to use this. Most warehouses don't support multiple regression out of the box, so this satisfies a niche for those database tools which don't.

That said, even in BigQuery, it may be very useful to extract coefficients within a query instead of generating a separate `MODEL` object through a DDL statement, for a few reasons. Even in more black box predictive contexts, being able to predict in the same `SELECT` statement as training can be convenient. Additionally, BigQuery does not expose model coefficients to users, and this can be a dealbreaker in many contexts where you care about your coefficients as measurements, not as predictive model parameters. Lastly, `group_by` is akin to estimating parameters for multiple linear regressions at once.

Overall, I would say this is pretty different from what BigQuery's `CREATE MODEL` is doing; use whatever makes sense for your use case! But keep in mind that for large numbers of variables, a native implementation of linear regression will be noticeably more efficient than this implementation.

### Why is L2 regularization / ridge regression supported, but not L1 regularization / LASSO supported?

There is no closed-form solution to L1 regularization, which makes it very very hard to add through raw SQL. L2 regularization has a closed-form solution and can be implemented using a pre-processing trick.

### Is the `group_by=[...]` argument like categorical variables / one-hot encodings?

No. You should think of the group by more as a [seemingly unrelated regressions](https://en.wikipedia.org/wiki/Seemingly_unrelated_regressions) implementation than as a categorical variable implementation. It's running multiple regressions and each individual partition is its own `y` vector and `X` matrix. This is _not_ a replacement for dummy variables.

### Why aren't categorical variables / one-hot encodings supported?

I opt to leave out dummy variable support because it's tricky, and I want to keep the API clean and mull on how to best implement that at the highest level.

Note that you couldn't simply add categorical variables in the same list as numeric variables because Jinja2 templating is not natively aware of the types you're feeding through it, nor does Jinja2 know the values that a string variable can take on. The way you would actually implement categorical variables is with `group by` trickery (i.e. center both y and X by categorical variable group means), although I am not sure how to do that efficiently for more than one categorical variable column.

If you'd like to regress on a categorical variable, for now you'll need to do your own feature engineering, e.g. `(foo = 'bar')::int as foo_bar`

# Trademark & Copyright

dbt is a trademark of dbt Labs.

This package is **unaffiliated** with dbt Labs.
