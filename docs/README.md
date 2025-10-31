# MatNWB Documentation

This directory contains the documentation for MatNWB, built using Sphinx.

## Building the Documentation Locally

### Prerequisites

1. **Install Python dependencies:**
   ```bash
   cd docs
   pip install -r requirements.txt
   ```
   
   This installs the required packages:
   - sphinx
   - sphinx-rtd-theme
   - sphinx-copybutton
   - sphinxcontrib-matlabdomain

### Build the Documentation

**On macOS/Linux:**
```bash
cd docs
make html
```

**On Windows:**
```bash
cd docs
make.bat html
```

### View the Documentation

After building, open `docs/build/html/index.html` in your web browser to view the generated documentation.

### Other Build Options

- `make clean` - Remove build files
- `make help` - See all available build targets
- `make linkcheck` - Check for broken links

## Documentation Structure

- `source/` - Source files for the documentation
  - `pages/` - Main documentation pages
  - `conf.py` - Sphinx configuration
- `build/` - Generated documentation (created after building)
- `requirements.txt` - Python dependencies for building docs
- `Makefile` - Build commands for Unix systems
- `make.bat` - Build commands for Windows

## Contributing to Documentation

When editing documentation:

1. Make changes to files in the `source/` directory
2. Build locally to test your changes
3. Ensure the documentation builds without warnings

The documentation uses reStructuredText (`.rst`) format. See the [Sphinx documentation](https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html) for syntax reference.
