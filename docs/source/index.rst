.. include:: _links.rst

##############
NWB for MATLAB
##############

MatNWB_ is a MATLAB package for working with |NWB|_ (NWB) files. 
It provides a high‑level, efficient interface for reading and writing neurophysiology data in the NWB format and includes tutorial Live Scripts that guide you through converting and organizing your own data.

This documentation focuses on MatNWB. If you are new to NWB or want to learn more about the format itself, these resources are a great starting point:

..
  - :nwb_overview:`NWB Overview` | Placeholder

- `NWB Overview Introduction <https://nwb-overview.readthedocs.io/en/latest/intro_to_nwb/1_intro_to_nwb.html>`_: Entry point providing a high-level and general overview of the NWB format

- `NWB Format Specification <https://nwb-schema.readthedocs.io/en/latest/index.html#>`_: Detailed overview of the NWB Format and the neurodata type specifications that make up the format. 

For a quick introduction to MatNWB, go to the :ref:`Overview <matnwb-overview>`
page. If you immediately want to see how to read or write files, take a look at the 
:ref:`Quickstart <quickstart-tutorial>` tutorial.

For more in-depth examples of how to create NWB files, we recommend you to start 
with the :ref:`Introduction<intro-tutorial>` tutorial and then move on to one or 
more of the domain-focused tutorials:

- :ref:`behavior-tutorial`
- :ref:`ecephys-tutorial`
- :ref:`icephys-tutorial`
- :ref:`images-tutorial`
- :ref:`ogen-tutorial`
- :ref:`ophys-tutorial`

To explore the growing world of open-source neuroscience data stored in the 
NWB format, check out the :ref:`Read from Dandihub<read_demo_dandihub-tutorial>` how-to-guide.

This documentation is based on the `diataxis <https://diataxis.fr>`_ framework. 
When you browse the table of contents below, look for tutorials, how-to-guides, 
concepts (explanation) and reference sections to help orient yourself.

.. toctree::
   :maxdepth: 1
   :caption: Get Started

   pages/getting_started/overview
   pages/getting_started/installation
   pages/getting_started/quickstart

.. toctree::
   :maxdepth: 2
   :caption: Tutorials
    
   pages/tutorials/index

.. toctree::
   :maxdepth: 2
   :caption: How-tos
   
   pages/how_to/index

.. toctree::
   :maxdepth: 2
   :caption: Concepts
  
   pages/concepts/considerations
   pages/concepts/file_read
   pages/concepts/file_create
   pages/concepts/using_extensions

.. toctree::
   :maxdepth: 1
   :caption: MatNWB Reference
   
   pages/functions/index
   pages/neurodata_types/core/index
   pages/neurodata_types/hdmf_common/index
   pages/neurodata_types/hdmf_experimental/index

.. toctree::
   :maxdepth: 2
   :caption: For Developers

   pages/developer/contributing
   pages/developer/documentation
   pages/developer/releases

