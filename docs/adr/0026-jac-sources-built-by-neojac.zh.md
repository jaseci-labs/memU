# ADR 0026：由 neojac 构建的 Jac 源码

- 状态：提案；已实现，待审阅
- [English](0026-jac-sources-built-by-neojac.md)

## 目标 {#goal}

用 Jac 编写 `memu` 包，由 neojac 工具链构建，同时保持发布的 Python 包、行为和测试套件不变。

## 决策 {#decision}

`jac.toml` 承载原 `pyproject.toml` 与 `npm/package.json` 的内容；`archwire.jac` 将包声明为 `cpython` space `memu`，测试和脚本为 `memu_dev`，包内模块间的每个导入都是一条 wire。`src/memu` 下的模块为 Jac，每个模块一个文件，函数体内联：`jac.toml` 选用 `style` lint 规则而非 neojac 默认的 `clean`，后者的 `separate-impls` 会在 `impl/` 附属文件中重复每个签名（约多 1,200 行）。被替换的 Python 源码不再保留在源码树中（git 历史保留）；`replaced-by-neojac/` 只保留由 `jac.toml` 与 `jac.lock` 取代的清单和锁文件。

三处保持 Python：

- `hosts/_extraction_runner.py`：以 `python -I -S` 独立脚本运行，无法加载 Jac 运行时；
- `database/postgres/migration.py`：其测试按文件路径加载；
- `database/postgres/migrations/` 下的 alembic 脚本。

重写不改变任何公开名称、结果结构或存储契约。Jac 与 Python 语义不同之处均显式处理：

- 函数内导入写作 `importlib.import_module`，因为 wire 在使用方加载时即加载提供方。
- 测试在使用方上打补丁的名称绑定为模块副本，与 Python `from x import y` 一致；wire 名称从提供方读取。
- 作为 SQL 子句保留值的比较写作 `operator.eq`，因为 Jac 的 `==` 结果为 `bool`。
- 容器或 `None` 类型写作 `Optional[...]`，读取循环变量的生成器改为列表推导，以规避当前 neojac 运行时的两处转换问题。

SQLite 与 Postgres 后端通过 `database/sql_common` 共享表模型构建器与仓库基础代码。

## 验证 {#validation}

`neojac test` 构建包并对构建产物运行现有测试：1575 通过，34 跳过。4 个失败与未移植的 Python 代码在 neojac 的 CPython 3.15 上的失败相同（3 个 Windows 路径用例和 1 个 Hermes 后台 worker 用例）。pydantic、pydantic-core 和 jiter 因锁定版本没有该 CPython 的 wheel 而接受偏离 `uv.lock`；`psycopg-binary` 在该环境未安装，因此 Postgres 路径已通过检查但未实际运行。
