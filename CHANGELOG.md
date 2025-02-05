# Changelog

### `0.3.1`

- Fix bug in `vars:` implementation of method options.

### `0.3.0`

- Official support for Clickhouse!
- Rename `format=` and `format_options=` to `output=` and `output_options=` to make the API consistent with **dbt_pca**.
- Allow for setting method and output options globally with `vars:`

### `0.2.6`

- Fix bug with `group_by` on multiple variables; contributed by [@svkohler](https://github.com/dwreeves/dbt_linreg/issues/21).

### `0.2.5`

- Fix bug where `exog` and `group_by` did not handle `str` inputs e.g. `exog="x"`.
- Fix bug where `group_by` for `method='fwl'` with exactly 1 exog variable did not work. (Explanation: `method='fwl'` dispatches to a different macro for the special case of 1 exog variable, and `group_by` was not implemented correctly here.)
- Fix bug where `safe` mode did not work for `method='chol'`.
- Improved docs by hiding everything except `ols()`, improved description of `ols()` macro, and added missing arg.

### `0.2.4`

- Fix minor incompatibility with Redshift; contributed by [@steelcd](https://github.com/steelcd).

### `0.2.3`

- Added Postgres support in integration tests + fixed bugs that prevented Postgres from working.

### `0.2.2`

- Added dbt documentation of the `ols()` macro.

### `0.2.1`

- Added `.dbtignore`.

### `0.2.0`

- Add `chol` method to `dbt_linreg.ols()`, and also set as the default method. (This method is significantly faster than `fwl`, and has a few other benefits.)
- Add standard error column in `long` format for `chol` method.

### `0.1.2`

- Added the ability to turn off/on the constant term with `add_constant: bool = True` kwarg.
- Fixed error that occurred when rendering a 1-variable ridge regression.

### `0.1.1`

- Fixed namespacing issue with CTEs-- all CTEs generated by `dbt_linreg` now start with `_dbt_linreg_`, to reduce namespace conflicts with user generated SQL.
- Locked the dbt-core version requirement to `>=1.2.0` (for now) because one of this package's dependencies (`modules.itertools.combinations`) is not available prior to `1.2.0`.

### `0.1.0`

- Initial release
