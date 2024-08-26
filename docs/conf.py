# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'MatNWB'
copyright = '2023, The NeurodataWithoutBorders Team'
author = 'The NeurodataWithoutBorders Team'
release = '2.6.0.2'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = ['sphinxcontrib.matlab', 'sphinx.ext.autodoc']

templates_path = ['_templates']
exclude_patterns = []
matlab_src_dir = "."


# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

primary_domain = "mat"

html_theme = "sphinx_rtd_theme"
html_logo = "../../logo/logo_matnwb.svg"
html_static_path = ['_static']

matlab_auto_link = "all"
matlab_show_property_default_value = True
matlab_class_signature = True