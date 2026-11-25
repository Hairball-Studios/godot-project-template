# What the checks catch

What each check says when something is wrong. Every message here came from running the tool on
bad code written for the purpose. `mise run check` runs them all: the layout checks
(`format-check`), the linters (`lint`) and the tests (`test`).

## GDScript

**Warnings treated as errors** (`project.godot`, `[debug]`): the engine refuses to load a script
with any of these, so every test and every run of the game shows them.

| Code | Message |
|---|---|
| `var untyped = 1` | `Variable "untyped" has no static type.` |
| An unused parameter or local | `The parameter "unused" is never used in the function "f()". If this is intended, prefix it with an underscore: "_unused".` |
| `var whole: int = 3.7` | `Narrowing conversion (float is converted to int and loses precision).` |
| A statement after `return` | `Unreachable code (statement after return) in function "f()".` |

A `match` that leaves out a value of an enum is not reported; review those by eye.

**`gdlint`** (`.gdlintrc`): naming and structure.

| Code | Message |
|---|---|
| `func DoThing(...)` | `Function name "DoThing" is not valid (function-name)` |
| `var Bad_Name := 1` | `Class-scope variable name "Bad_Name" is not valid (class-variable-name)` |
| A `signal` after a `var`, or a `const` after an `@export` | `Definition out of order in global scope (class-definitions-order)` |
| Seven `return`s in one function | `Function "DoThing" has more than 6 return statements (max-returns)` |
| An argument the function never uses | `unused function argument 'unused' (unused-argument)` |

A comment on the line above sets a rule aside for one line: `# gdlint: ignore=unused-argument`.
The parameterised tests use it for gdUnit4's `test_parameters`, which the framework reads and
the function does not.

**`gdscript-formatter`**: one layout for every file, so a diff shows only what changed.
`var x=1` and `func f( a:int )->int :` fail `format-check` with `Some files are not formatted`;
`mise run format` rewrites them.

**`tools/load_all_scripts.gd`** (the last step of `mise run format`): loads every script and
prints `UNLOADABLE res://...` for any the engine cannot parse, in case the formatter wrote a
file the engine rejects.

## Python

**`ruff`** (`ruff.toml`): ruff's default rules, plus limits on size and branching.

| Code | Message |
|---|---|
| `import os` that is never used | `F401 imported but unused` |
| `except:` with no exception named | `E722 Do not use bare except` |
| A function with six parameters | `PLR0913 Too many arguments in function definition (6 > 5)` |
| A function that branches too much | `C901`, `PLR0911`, `PLR0912` or `PLR0915`, at the limits in `ruff.toml` |

**`mypy`** (`mypy.ini`, strict about annotations):

| Code | Message |
|---|---|
| `def f(a, b: int)` | `Function is missing a type annotation for one or more parameters [no-untyped-def]` |
| Returning `"no"` from a function declared `-> int` | `Incompatible return value type (got "str", expected "int") [return-value]` |

## C++

**`clang-format`** (`.clang-format`): one layout, as for GDScript.

**`clang-tidy`** (`.clang-tidy`): every report is an error.

| Code | Message |
|---|---|
| `int count;` read before it is set | `variable 'count' is not initialized [cppcoreguidelines-init-variables]` |
| The same variable, on the path where it is still unset | `The left operand of '+' is a garbage value [clang-analyzer-core.UndefinedBinaryOperatorResult]` |
| `if (a > 1)` with no braces | `statement should be inside braces [readability-braces-around-statements]` |
| `int *p` that is never changed through | `pointee of variable 'p' of type 'int *' can be declared 'const' [misc-const-correctness]` |
| `NULL` | `use nullptr [modernize-use-nullptr]` |
| A header that is used but not included | `no header providing "int64_t" is directly included [misc-include-cleaner]` |
| A function over 60 lines | `readability-function-size` |

## Tests

**`tools/run_tests.py`** runs the [gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) tests
in a headless engine. A run fails on a non-zero exit (gdUnit4 exits 100 for an error and 101 for
a warning), a timeout, or any output line with `ERROR:`, `WARNING:` or `SCRIPT ERROR`, so an
engine error no test asserted on still fails the run.

A failed assertion names the test, the row of a parameterised one, and what it expected. A
speed clamp broken to take the wrong bound:

```
res://tests/test_game_settings.gd > test_the_game_speeds_up_as_food_is_eaten:4 (100, 0.1) FAILED 2ms
  Expecting:
 -0.800000
 in range between
 0.099900 <> 0.100100
```

A pause that did nothing, found through the scene and a simulated key press:

```
res://tests/test_main_scene.gd > test_p_pauses_the_game_and_p_resumes_it FAILED 20ms
  Expecting: 'true' but is 'false'
```

A node a test creates and does not free is reported as `WARNING: Detected 7 possible orphan
nodes.`, which fails the run. Tests free what they make with `auto_free`, or with a scene runner
for a scene it loads itself.
