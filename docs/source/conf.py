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
from custom_roles import MatClassRole, register_matlab_types, register_type_short_names

def setup(app):
    app.connect("autodoc-process-docstring", process_matlab_docstring)
    app.connect("env-purge-doc", register_matlab_types)
    app.connect("env-purge-doc", register_type_short_names)
    app.add_role('matclass', MatClassRole())


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
    'sphinx.ext.linkcode',
    'sphinx.ext.extlinks', # For maintaining external links
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


def linkcode_resolve(domain, info):
    filename = info['module'].replace('.', '/')
    source_url = 'https://github.com/NeurodataWithoutBorders/matnwb/blob/main/'+filename+'/'+info['fullname']+'.m'
    print(source_url)
    return source_url


# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = "sphinx_rtd_theme"

html_static_path = ['_static']
html_logo = os.path.join(matlab_src_dir, 'logo', 'logo_matnwb_small.png')
html_favicon = os.path.join(matlab_src_dir, 'logo', 'logo_favicon.svg')

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


# External links used in the documentation 
extlinks = {
    'incf_lesson': ('https://training.incf.org/lesson/%s', '%s'),
    'incf_collection': ('https://training.incf.org/collection/%s', '%s'),
    'nwb_extension': ('https://github.com/nwb-extensions/%s', '%s'),
    'pynwb': ('https://github.com/NeurodataWithoutBorders/pynwb/%s', '%s'),
    'nwb_overview': ('https://nwb-overview.readthedocs.io/en/latest/%s', '%s'),
    'hdmf-docs': ('https://hdmf.readthedocs.io/en/stable/%s', '%s'),
    'dandi': ('https://www.dandiarchive.org/%s', '%s'),
    "nwbinspector": ("https://nwbinspector.readthedocs.io/en/dev/%s", "%s"),
    'hdmf-zarr': ('https://hdmf-zarr.readthedocs.io/en/latest/%s', '%s'),
    'matlab-online-tutorial': ('https://matlab.mathworks.com/open/github/v1?repo=NeurodataWithoutBorders/matnwb&file=tutorials/%s.mlx', '%s'),
    'nwb-core-type-schema': ('https://nwb-schema.readthedocs.io/en/latest/format.html#%s', '%s'),
    'nwb-hdmf_common-type-schema': ('https://hdmf-common-schema.readthedocs.io/en/stable/format.html#%s', '%s'),
    'nwb-hdmf_experimental-type-schema': ('https://hdmf-common-schema.readthedocs.io/en/stable/format.html#%s', '%s')
}
