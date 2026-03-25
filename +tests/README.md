# MatNWB Test Suite

This document explains how to set up and run the MatNWB test suite.

## Prerequisites

- **MATLAB** R2021a or newer
- **Python** 3.10 or newer (for Python-dependent tests)
- Python must be configured in MATLAB via `pyenv` (verify with `pyenv` at the MATLAB command prompt)

## Quick start

From the MatNWB root directory in MATLAB:

```matlab
% Run all tests
nwbtest()

% Run only unit tests
nwbtest('Name', 'tests.unit.*')

% Run only system tests
nwbtest('Name', 'tests.system.*')

% Run tests matching a specific procedure name
nwbtest('ProcedureName', 'testSmoke*')

% Run tests with detailed output
nwbtest('Verbosity', 3)
```

`nwbtest` produces a JUnit XML test report (`testResults.xml`) and a Cobertura
code coverage report (`coverage.xml`), both written to `docs/reports/<timestamp>/`.

## Test packages

| Package | Description |
|---|---|
| `+tests/+unit/` | Unit tests for individual components (schema, I/O, types) |
| `+tests/+system/` | Integration tests (round-trip, NWB file I/O, PyNWB interop) |
| `+tests/+system/+tutorial/` | Tutorial validation tests |
| `+tests/+sanity/` | Sanity checks (e.g., type generation) |

Supporting packages:

| Package | Description |
|---|---|
| `+tests/+abstract/` | Abstract base test classes (`NwbTestCase`) |
| `+tests/+factory/` | Factory classes for creating test objects |
| `+tests/+fixtures/` | Shared test fixtures (environment setup, type generation) |
| `+tests/+util/` | Test utility functions |

## Setting up Python-dependent tests

Some tests use Python for PyNWB interoperability and NWB file validation.
These tests are tagged `UsesPython` and require additional setup.

### 1. Install Python packages

Packages must be installed into the Python environment that MATLAB uses.
Check which Python executable MATLAB is configured to use:

```matlab
>> pyenv
```

Then install the dependencies using that executable:

```bash
/path/to/python -m pip install -r +tests/requirements.txt
/path/to/python -m pip install pynwb nwbinspector
```

Replace `/path/to/python` with the `Executable` shown by `pyenv`.

Or install directly from the MATLAB command window:

```matlab
pythonExecutable = pyenv().Executable;
system(pythonExecutable + " -m pip install -r +tests/requirements.txt")
system(pythonExecutable + " -m pip install pynwb nwbinspector")
```

### 2. Clone the PyNWB repository

The `PynwbTutorialTest` suite runs PyNWB tutorial scripts and validates
that MatNWB can read the resulting files. It requires a local clone of the
PyNWB repository. Clone it **outside** the MatNWB directory to avoid
accidentally including it in the MatNWB repository:

```bash
cd /path/to/your/repos
git clone https://github.com/NeurodataWithoutBorders/pynwb.git
```

### 3. Configure environment variables

Copy the default environment file and edit it:

```bash
cp +tests/nwbtest.default.env +tests/nwbtest.env
```

Edit `nwbtest.env` to set paths for your local environment:

```ini
# Path to the nwbinspector executable
NWBINSPECTOR_EXECUTABLE=nwbinspector

# Path to the Python executable (should match pyenv in MATLAB)
PYTHON_EXECUTABLE=python

# Path to your local pynwb clone (required for PynwbTutorialTest)
PYNWB_REPO_DIR=/path/to/pynwb

# Set to 1 to skip all Python-dependent tests
SKIP_PYNWB_TESTS=0
```

The test fixture `tests.fixtures.SetEnvironmentVariableFixture` loads these
variables at test startup. If `nwbtest.env` does not exist, it falls back to
`nwbtest.default.env`.

### Skipping Python tests

If Python is not available or not needed, skip all Python-dependent tests:

```matlab
setenv('SKIP_PYNWB_TESTS', '1')
nwbtest()
```

Or set `SKIP_PYNWB_TESTS=1` in your `nwbtest.env` file.

## Setting up dynamically loaded HDF5 filter tests

Tests tagged `UsesDynamicallyLoadedFilters` require MATLAB R2022a or newer and
HDF5 filter plugins to be available. The easiest way to set this up is via the
`hdf5plugin` Python package.

`hdf5plugin` must be installed into the same Python environment that MATLAB
uses. Check the executable with `pyenv` in MATLAB first, then use it for all
commands below.

### macOS / Linux

```bash
/path/to/python -m pip install hdf5plugin
export HDF5_PLUGIN_PATH=$(/path/to/python -c "import hdf5plugin; print(hdf5plugin.PLUGINS_PATH)")
```

Then launch MATLAB **from that same terminal session** so it inherits the
`HDF5_PLUGIN_PATH` environment variable.

### Windows

```bat
C:\path\to\python.exe -m pip install hdf5plugin
C:\path\to\python.exe -c "import hdf5plugin; print(hdf5plugin.PLUGINS_PATH)"
```

Copy the printed path, then set `HDF5_PLUGIN_PATH` via
_System Properties > Advanced > Environment Variables_ and restart MATLAB.


## Test conventions

- Test classes inherit from `matlab.unittest.TestCase` (or `tests.abstract.NwbTestCase` for tests that need generated NWB types)
- Test method names start with `test` (e.g., `testSmoke`, `testRoundTrip`)
- Python-dependent tests are tagged `UsesPython`
- Tests requiring dynamically loaded HDF5 filters are tagged `UsesDynamicallyLoadedFilters` (MATLAB R2022a+)

### Placing `TestTags` on the `methods` block, not the classdef

Tags must be declared on the `methods (Test, TestTags = {...})` block rather
than on the `classdef` line. Placing tags on the classdef causes a parsing
issue with the MATLAB domain for Sphinx documentation generation
([sphinx-contrib/matlabdomain#281](https://github.com/sphinx-contrib/matlabdomain/issues/281)).

```matlab
% Correct
methods (Test, TestTags = {'UsesPython'})
    function testSomething(testCase)
        ...
    end
end

% Avoid
classdef (TestTags = {'UsesPython'}) MyTest < matlab.unittest.TestCase
    ...
end
```

### Using `nwbRead` in tests

When calling `nwbRead` in a test, you **must** do one of the following:

- Pass the `"ignorecache"` flag, **or**
- Set the `"savedir"` option to your test's temp folder

If you don't, MatNWB will write generated type definitions into its default
(root) directory, causing path conflicts with the test suite's own temporary
location.

Examples:

```matlab
nwbObject = nwbRead(filePath, "ignorecache");
nwbObject = nwbRead(filePath, "savedir", '.');
```
