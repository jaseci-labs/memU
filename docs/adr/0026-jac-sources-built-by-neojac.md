# ADR 0026: Jac Sources Built by neojac

- Status: Proposed; implemented for review
- [中文](0026-jac-sources-built-by-neojac.zh.md)

## Goal {#goal}

Write the `memu` package in Jac, built by the neojac toolchain, while keeping the published Python package, its behavior and its test suite unchanged.

## Decision {#decision}

`jac.toml` holds what `pyproject.toml` and `npm/package.json` held, and `archwire.jac` declares the package as the `cpython` space `memu`, its tests and scripts as `memu_dev`, and every import between the package's modules as a wire. The modules under `src/memu` are Jac, one file each with its bodies inline: `jac.toml` selects the `style` lint rules rather than neojac's default `clean`, whose `separate-impls` would repeat every signature in an `impl/` annex (about 1,200 more lines). The Python sources they replace are not kept in the tree (git history holds them); `replaced-by-neojac/` keeps only the manifests and lock that `jac.toml` and `jac.lock` stand in for.

Three files stay Python:

- `hosts/_extraction_runner.py`, which runs as a standalone script under `python -I -S` and so cannot load the Jac runtime;
- `database/postgres/migration.py`, which its test loads by file path;
- the alembic scripts under `database/postgres/migrations/`.

The rewrite changes no public name, result shape or storage contract. Where Jac differs from Python, the code says so explicitly:

- An import inside a function is an `importlib.import_module` call, since a wire loads its provider when the consumer loads.
- A name tests patch on a consumer is bound as a module copy, as Python's `from x import y` binds one; a wired name is read from its provider.
- A comparison whose value is kept as an SQL clause is `operator.eq`, since Jac's `==` is a `bool`.
- A container-or-`None` type is written `Optional[...]`, and a generator that reads a loop variable is a list comprehension, working around two conversions of the current neojac runtime.

The SQLite and Postgres backends share their table-model builder and repository plumbing through `database/sql_common`.

## Validation {#validation}

`neojac test` builds the package and runs the existing suite against the build: 1575 passed and 34 skipped. The four failures are the same four the unported Python code fails on neojac's CPython 3.15 (three Windows-path cases and one Hermes detached-worker test). pydantic, pydantic-core and jiter are accepted off their `uv.lock` pins because those versions have no wheel for that CPython, and `psycopg-binary` is not installed there, so the Postgres paths are checked but not exercised.
