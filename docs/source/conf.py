# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

import os
import sys

sys.path.append('sphinx_extensions')
from docstring_processors import process_matlab_docstring

def setup(app):
    app.connect("autodoc-process-docstring", process_matlab_docstring)

project = 'MatNWB'
copyright = '2024, Neurodata Without Borders' # Todo: compute year
author = 'Neurodata Without Borders'

release = '2.7.0' # Todo: read from Contents.m

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    "sphinx.ext.mathjax",  # or other extensions you may need
    'sphinxcontrib.matlab', # generate docs for matlab functions
    'sphinx.ext.autodoc', # autogenerate docs
    'sphinx.ext.napoleon', # for parsing e.g google style parameter docstring
    'sphinx.ext.viewcode',
    'sphinx_copybutton',
]

# -- Options that are MATLAB specific ----------------------------------------

highlight_language = 'matlab'

primary_domain = "mat"

# Get the absolute path of the script's directory
script_dir = os.path.dirname(os.path.abspath(__file__))

# Compute the absolute path two levels up from the script's directory
matlab_src_dir = os.path.abspath(os.path.join(script_dir, '..', '..'))

matlab_class_signature = True
matlab_auto_link = "all"
matlab_show_property_default_value = True

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = "sphinx_rtd_theme"

html_static_path = ['_static']
html_logo = os.path.join(matlab_src_dir, 'logo', 'logo_matnwb_small.png')
html_theme_options = {
    # "style_nav_header_background": "#AFD2E8"
    "style_nav_header_background": "#000000"
    }
    #    'navigation_depth': 1,  # Adjust the depth as needed

templates_path = ['_templates']
exclude_patterns = []
html_css_files = [
    'css/custom.css',
]
