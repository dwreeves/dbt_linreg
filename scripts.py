"""
This file is used for generation of CSV files for integration test cases,
and also for manual verification + generation of test case values.
"""
import os.path as op
import warnings
from typing import NamedTuple
from typing import Optional
from typing import Protocol

import numpy as np
import pandas as pd
import rich_click as click
import statsmodels.api as sm
from tabulate import tabulate


# Suppress iteritems warning
warnings.simplefilter("ignore", category=FutureWarning)

# No scientific notation
np.set_printoptions(suppress=True)


DIR = op.dirname(__file__)

DEFAULT_SIZE = 10_000
DEFAULT_SEED = 382479347


class TestCase(NamedTuple):
    df: pd.DataFrame
    x_cols: list[str]
    y_col: str
    group: Optional[str] = None


class TestCaseCallable(Protocol):
    def __call__(self, size: int, seed: int) -> TestCase:
        pass


def gram_schmidt(df: pd.DataFrame):
    q = pd.DataFrame(index=df.index)
    for c, v in df.items():
        v_new = v.copy()
        for _, u in q.items():
            v_new -= u * u.dot(v) / u.dot(u)
        q[c] = v_new / np.linalg.norm(v_new)
    return q


def simple_matrix(size: int = DEFAULT_SIZE, seed: int = DEFAULT_SEED) -> TestCase:
    # Gram Schmidt makes any matrix into the simplest test case because
    # orthogonalization guarantees round and predictable coefficients.
    #
    # That said, we also want to cover test cases unorthogonalized.
    # Otherwise, it kind of beats the point of writing all that multiple
    # regression logic using the FWL theorem.
    #
    # So although it is a good and clean test case, it can't be the only one.
    rs = np.random.RandomState(seed=seed)
    df = pd.DataFrame(index=range(size))
    df["const"] = 1

    coefficients = pd.Series({
        "const": 10,
        "xa": 5,
        "xb": 7,
        "xc": 9,
        "xd": 11,
        "xe": 13,
        "xf": 15,
        "xg": 17,
        "xh": 19,
        "xi": 21,
        "xj": 23
    })

    for c in coefficients.index:
        if c == "const":
            continue
        df[c] = rs.normal(0, 1, size=size)
    df["epsilon"] = rs.normal(0, 10, size=size)

    feature_cols = list(coefficients.index)
    x_cols = [i for i in feature_cols if i != "const"]
    non_const_cols = x_cols + ["epsilon"]

    # Center the non-constant columns
    # This is kinda like orthogonalizing w/r/t constant term.
    # So doing this here means we don't need to Gram Schmidt the constant.
    for c in non_const_cols:
        df[c] -= df[c].mean()

    df[non_const_cols] = gram_schmidt(df[non_const_cols])

    df["y"] = df[feature_cols].dot(coefficients) + df["epsilon"]

    return TestCase(df=df, y_col="y", x_cols=x_cols)


def collinear_matrix(size: int = DEFAULT_SIZE, seed: int = DEFAULT_SEED) -> TestCase:
    rs = np.random.RandomState(seed=seed)
    df = pd.DataFrame(index=range(size))
    df["const"] = 1
    df["x1"] = 2 + rs.normal(0, 1, size=size)
    df["x2"] = 1 - df["x1"] + rs.normal(0, 3, size=size)
    df["x3"] = 3 + 2 * df["x2"] + rs.normal(0, 1, size=size)
    df["x4"] = -3 + 0.5 * (df["x1"] * df["x3"]) + rs.normal(0, 1, size=size)
    df["x5"] = 4 + 0.5 * np.sin(3 * df["x2"]) + rs.normal(0, 1, size=size)
    df["epsilon"] = rs.normal(0, 4, size=size)

    coefficients = pd.Series({
        "const": 20,
        "x1": 5,
        "x2": 7,
        "x3": 9,
        "x4": 11,
        "x5": 13
    })

    x_cols = list(coefficients.index)

    # coefficients will not exactly match due to OVB
    df["y"] = (
        df[coefficients.index].dot(coefficients)
        + (df["x3"] + np.sin(df["x1"])) ** 2
        + df["epsilon"]
    )

    return TestCase(df=df, y_col="y", x_cols=x_cols)


def groups_matrix(size: int = DEFAULT_SIZE, seed: int = DEFAULT_SEED) -> TestCase:
    rs = np.random.RandomState(seed=seed)
    size1 = size // 2
    size2 = size - size1

    df1 = pd.DataFrame(index=range(size1))
    df1["gb_var"] = "a"
    df1["const"] = 1
    df1["x1"] = 2 + rs.normal(0, 1, size=size1)
    df1["x2"] = 1 - df1["x1"] + rs.normal(0, 3, size=size1)
    df1["x3"] = 3 + 2 * df1["x2"] + rs.normal(0, 1, size=size1)
    df1["y"] = 1 * df1["x1"] + 2 * df1["x2"] + 3 * df1["x2"] + rs.normal(0, 1, size=size1)

    df2 = pd.DataFrame(index=range(size2))
    df2["gb_var"] = "b"
    df2["const"] = 1
    df2["x1"] = 6 + rs.normal(0, 3, size=size2)
    df2["x2"] = 3 + df2["x1"] + rs.normal(0, 3, size=size2)
    df2["x3"] = -1 - df2["x2"] + rs.normal(0, 2, size=size2)
    df2["y"] = 2 + 3 * df2["x1"] + 4 * df2["x2"] + 5 * df2["x2"] + rs.normal(0, 1, size=size1)

    df = pd.concat([df1, df2], axis=0).reset_index()

    return TestCase(
        df=df,
        y_col="y",
        x_cols=["const", "x1", "x2", "x3"],
        group="gb_var"
    )


ALL_TEST_CASES: dict[str, TestCaseCallable] = {
    "simple_matrix": simple_matrix,
    "collinear_matrix": collinear_matrix,
    "groups_matrix": groups_matrix
}


def click_option_seed(**kwargs):
    return click.option(
        "--seed", "-s",
        default=DEFAULT_SEED,
        show_default=True,
        help="Seed used to generate data.",
        **kwargs
    )


def click_option_size(**kwargs):
    return click.option(
        "--size", "-n",
        default=DEFAULT_SIZE,
        show_default=True,
        help="Number of rows to generate.",
        **kwargs
    )


@click.group("main", context_settings=dict(help_option_names=["-h", "--help"]))
def cli():
    """CLI for manually testing the code base."""


@cli.command("regress")
@click.option("--table", "-t",
              required=True,
              type=click.Choice(ALL_TEST_CASES.keys()),
              help="Table to regress against.")
@click.option("--const/--no-const",
              default=True,
              type=click.BOOL,
              show_default=True,
              help="If true, add the constant term.")
@click.option("--columns", "-c",
              default=None,
              type=click.INT,
              show_default=True,
              help="Number of columns to regress.")
@click.option("--alpha", "-a",
              default=None,
              type=click.FLOAT,
              show_default=True,
              help="Alpha for the regression.")
@click.option("--weights", "-w",
              default=None,
              type=click.STRING,
              show_default=True,
              help="Weight column for regression.")
@click_option_size()
@click_option_seed()
def regress(table: str, const: bool, columns: int, alpha: float, size: int, seed: int, weights: str):
    """
    Run regression on integration test cases.

    Use me for either manual verification of test cases, or for generating new
    test cases. (All numeric values for test cases were generated using this
    CLI.)
    """
    callback = ALL_TEST_CASES[table]

    click.echo(click.style("=" * 80, fg="blue"))
    click.echo(
        click.style("Test case: ", fg="blue", bold=True)
        +
        click.style(table, fg="blue")
    )
    click.echo(click.style("=" * 80, fg="blue"))

    test_case = callback(size, seed)

    if columns is None:
        x_cols = test_case.x_cols
    else:
        # K plus Constant (1)
        x_cols = test_case.x_cols[:columns+1]

    if not const:
        x_cols = [i for i in x_cols if i != "const"]

    def _run_model(cond=None):
        if cond is None:
            cond = slice(None)
        y = test_case.df.loc[cond, test_case.y_col]
        x_mat = test_case.df.loc[cond, x_cols]
        kw = {}
        if weights:
            kw["weights"] = np.abs(test_case.df[weights])
        if alpha:
            if const:
                alpha_arr = [0, *([alpha] * (len(x_mat.columns) - 1))]
            else:
                alpha_arr = [alpha] * len(x_mat.columns)
            model = sm.WLS(
                y,
                x_mat,
                **kw,
            ).fit_regularized(L1_wt=0.00000001, alpha=alpha_arr)
        else:
            model = sm.WLS(y, x_mat, **kw).fit()
        res_df = pd.DataFrame(index=x_mat.columns)
        res_df["coef"] = model.params
        if not alpha:
            res_df["stderr"] = model.bse
            res_df["tstat"] = res_df["coef"] / res_df["stderr"]
        click.echo(
            tabulate(
                res_df,
                headers=["column name", "coef", "stderr", "tstat"],
                disable_numparse=True,
                tablefmt="psql",
            )
        )

    if test_case.group:
        for c in test_case.df[test_case.group].unique():
            click.echo(click.style(f"{test_case.group} - {c}", fg="green"))
            _run_model(cond=(test_case.df[test_case.group] == c))
    else:
        _run_model()


def echo_table_name(s: str):
    click.echo(click.style("=" * 80, fg="green"))
    click.echo(
        click.style("Table: ", fg="green", bold=True)
        +
        click.style(s, fg="green")
    )
    click.echo(click.style("=" * 80, fg="green"))


@cli.command("gen-test-cases")
@click.option("--table", "-t", "tables",
              multiple=True,
              default=None,
              show_default=True,
              help="Generate a specific table. If None, generate all tables.")
@click_option_size()
@click_option_seed()
@click.option("--skip-if-exists", is_flag=True,
              help="Skip if the file exists. Otherwise, overwrite.")
def gen_test_cases(tables: list[str], size: int, seed: int, skip_if_exists: bool):
    """Generate integration test cases (CSV files)."""
    if not tables:
        tables = ALL_TEST_CASES
    for table_name in tables:
        file_name = f"{DIR}/integration_tests/seeds/{table_name}.csv"
        if skip_if_exists and op.exists(file_name):
            click.echo("File " + click.style(file_name, fg="blue") + " already exists; skipping.")
            continue

        callback = ALL_TEST_CASES[table_name]

        echo_table_name(table_name)

        test_case = callback(size, seed)
        y = test_case.df[test_case.y_col]
        x_mat = test_case.df[test_case.x_cols]

        click.echo()
        li = []
        for i in range(1, len(x_mat.columns) + 1):
            model = sm.OLS(
                y,
                sm.add_constant(x_mat.iloc[:, :i])
            ).fit()
            params = model.params.rename(f"{i}-var").reindex(x_mat.columns)
            params = params.apply(
                lambda s: "{:.5f}".format(s)
                if pd.notna(s)
                else None
            )
            expand_by = params.apply(lambda s: len(s) if s is not None else 0).max()
            params = params.where(
                pd.notna(params),
                click.style("-" * expand_by, fg="bright_black")
            )

            params.apply(lambda s: len(s)).max()
            li.append(params)
        coefs = pd.concat(li, axis=1)
        click.echo(
            tabulate(
                coefs,
                headers=coefs.columns,
                disable_numparse=True,
                tablefmt="psql",
            )
        )


        all_cols = [test_case.y_col, *test_case.x_cols]
        if test_case.group:
            all_cols.append(test_case.group)

        test_case.df[all_cols].to_csv(file_name, index=False)
        click.echo(
            click.style(f"Wrote DataFrame to file {file_name!r}", fg="yellow")
        )
        click.echo("")
    click.echo(click.style("Done!", fg="green"))


if __name__ == "__main__":
    cli()
