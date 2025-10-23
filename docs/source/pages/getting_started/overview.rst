.. include:: /_links.rst

.. _matnwb-overview:

Overview
========


What is MatNWB?
---------------

MatNWB_ is a MATLAB package for reading, writing, and validating NWB files. It provides simple functions like :func:`nwbRead` and :func:`nwbExport` for file I/O, as well as a complete set of core neurodata and helper types represented using MATLAB classes.


Who is it for?
--------------

- MATLAB users working with neurophysiology data (extracellular and intracellular electrophysiology, optical physiology, behavior, images, and derived analyses)
- Labs seeking a reproducible, self-describing data format that works seamlessly across platforms and is supported by an expanding ecosystem of tools and archives (e.g., DANDI).


What you can do with MatNWB
---------------------------

- Read NWB files

  - One call to :doc:`nwbRead </pages/functions/nwbRead>` opens a file and presents a hierarchical representation of the complete file and its contents.
  - Lazy I/O via DataStub lets you slice large datasets without loading them into RAM.

- Write NWB files

  - Build an :doc:`NwbFile </pages/functions/NwbFile>` with standard neurodata types (e.g., :doc:`TimeSeries </pages/neurodata_types/core/TimeSeries>`, :doc:`ElectricalSeries </pages/neurodata_types/core/ElectricalSeries>`, :doc:`Units </pages/neurodata_types/core/Units>`, :doc:`ImageSeries </pages/neurodata_types/core/ImageSeries>`).
  - Export to disk with :doc:`nwbExport </pages/functions/nwbExport>`.

- Scale to large data

  - Stream/append and compress data with the DataPipe interface.
  - Use predefined or custom configuration profiles to optimize files for local storage, cloud storage or archiving.

.. Todo: Add links to DataPipe reference and configuration profiles guide when these are added.

- Use NWB extensions

  - Install published Neurodata Extensions (NDX) with :doc:`nwbInstallExtension </pages/functions/nwbInstallExtension>` 
  - Generate classes from any namespace specification with :doc:`generateExtension </pages/functions/generateExtension>`.


How it works
------------

NWB files are containers for storing data and metadata in a hierarchical manner using groups and datasets. In this sense, an NWB file can be thought of as a tree of folders and files representing all the data associated with neurophysiological recording sessions. The data and metadata is represented through a set of neurodata types defined by the NWB schema. These neurodata types are the building blocks for NWB files and are often used together in specific configurations (see the :doc:`tutorials </pages/tutorials/index>` for concrete patterns)

MatNWB generates MATLAB classes representing these neurodata types from the NWB core schema or any available neurodata extension. These neurodata type classes ensure that data is always conforming to the NWB specification, and provide a structured interface for reading, writing, and validating NWB files. When you read an NWB file, MatNWB maps each group and dataset in the file to the corresponding MATLAB class, so you interact with neurodata types directly in MATLAB code. When you write or export, MatNWB serializes your MATLAB objects back to NWB-compliant HDF5 files, preserving the schema and relationships between types.

The main categories of types you will work with

- Metadata: subject and session descriptors (e.g., :doc:`Subject </pages/neurodata_types/core/Subject>`, :doc:`NWBFile </pages/neurodata_types/core/NWBFile>`, :doc:`Device </pages/neurodata_types/core/Device>`).
- Containers/wrappers: organize related data (e.g., :doc:`ProcessingModule </pages/neurodata_types/core/ProcessingModule>`).
- Time series: sampled data over time (e.g., :doc:`TimeSeries </pages/neurodata_types/core/TimeSeries>`, :doc:`ElectricalSeries </pages/neurodata_types/core/ElectricalSeries>`).
- Tables: columnar metadata or data (e.g., :doc:`DynamicTable </pages/neurodata_types/hdmf_common/DynamicTable>`).
- Helpers: :doc:`Helper types </pages/concepts/file_read/untyped>` for common patterns like references, links, and data I/O.

.. [Todo: expand, and link to helper types reference and concept pages when these are added].
.. [Todo: For tables: TimeIntervals, Units, ElectrodesTable]


Common questions you may encounter (and where to find answers)
--------------------------------------------------------------

- Which data type should I use?

  - Check out the :nwb_overview:`Neurodata Types <intro_to_nwb/3_basic_neurodata_types.html>` section in the NWB Overview Docs
  - Refer to the :doc:`Core neurodata types index </pages/neurodata_types/core/index>` for the full list of MatNWB types.

- Where in the file should a type go?

  - Check out the section :nwb_overview:`Anatomy of an NWB file <intro_to_nwb/2_file_structure.html>` in the NWB Overview Docs
  - Follow the domain tutorials for canonical placements (e.g., :doc:`Extracellular ephys </pages/tutorials/ecephys>`, :doc:`Calcium imaging </pages/tutorials/ophys>`, :doc:`Intracellular ephys </pages/tutorials/icephys>`).

- How do I name neurodata types when adding to sets?

  - Refer to the :nwbinspector:`Naming Conventions <best_practices/best_practices_index.html>` section of the NWB Inspector docs.

- What properties are required and how do I set them?

  - Each class page lists required fields and their types (e.g., :doc:`TimeSeries </pages/neurodata_types/core/TimeSeries>`).
  - Refer to the :nwbinspector:`Best Practices <best_practices/best_practices_index.html>` for more detailed recommendations.

- How do I add lab‑specific data?
  
  - See :doc:`Neurodata Extensions </pages/concepts/using_extensions>` for guides to install published NDX or to generate classes from your own namespace specification.


Important caveats when working with MatNWB:
-------------------------------------------

- **MATLAB vs. NWB dimension order** : The dimensions of datasets (arrays) in MatNWB are represented in the opposite order relative to the NWB specification. For example, in NWB the time dimension of a TimeSeries is the first dimension of a dataset, whereas in MatNWB, it will be the last dimension of the dataset. See the mappings and examples in the :doc:`Data dimensions </pages/concepts/dimension_ordering>` section for a detailed explanation.

- **NWB schema versions**: When reading an NWB file, MatNWB will dynamically build class definitions for neurodata types from schemas that are embedded in the file. This ensures that the file is always represented correctly according to the schema version (and extensions) that was used when creating the file. However, the generated type classes will take the place of previously existing classes (i.e generated from different NWB versions), and therefore it is not recommended to work with NWB files of different NWB versions simultaneously.

- **Editing NWB files**: If you need to edit NWB files after creation, note that MatNWB currently has certain limitations. See the section on :ref:`Editing NWB files <edit-nwb-files>` for more details.


Related resources
-----------------

- :nwb_overview:`NWB Overview <>` documentation
- Python API (PyNWB_)
- Object‑oriented programming refresher (MATLAB): https://www.mathworks.com/help/matlab/object-oriented-programming.html
- Share/discover data: :dandi:`DANDI Archive <>`


Cite MatNWB
-----------

If MatNWB contributes to your work, please see :doc:`Citing MatNWB </pages/getting_started/how_to_cite>`.