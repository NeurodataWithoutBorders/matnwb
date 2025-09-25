Creating NWB Files
==================

When creating an NWB file, you're translating your experimental data and metadata into a structure that follows the NWB schema. MatNWB provides MATLAB classes that represent the different components (neurodata types) of an NWB file, allowing you to build up the file piece by piece.

.. tip:: 
   To understand the general structure of an NWB file, the NWB Overview documentation has a 
   :nwb_overview:`great introduction <intro_to_nwb/2_file_structure.html>`.

As demonstrated in the :doc:`Quickstart </pages/getting_started/quickstart>` tutorial, when creating an NWB file, you start by invoking the :class:`NwbFile` class. This will return an :class:`NwbFile` object, a container whose properties are derived directly from the NWB schema. Some properties are required, others are optional. Some need specific MATLAB types like ``char`` or ``datetime``, while others need specific neurodata types defined in the NWB schema.

.. note::
    An "object" is an instance of a class. Objects are similar to MATLAB structs, but with additional functionality. The fields (called properties) are defined by the class definition (a .m file), and the class can enforce rules about what values are allowed. This helps ensure that your data conforms to the NWB schema.

**The Assembly Process**

Building an NWB file follows a logical pattern:

- **Create neurodata objects**: You create objects for your data (like :class:`types.core.TimeSeries` for time-based measurements)

- **Add to containers**: You add these data objects to your :class:`NwbFile` object (or other NWB container objects) in appropriate locations

- **File export**: You save everything to disk using :func:`nwbExport`, which translates your objects into NWB/HDF5 format

This approach ensures your data is properly organized and validated before it becomes a file.

**Schema Validation**

The NWB schema acts as a blueprint that defines what makes a valid neuroscience data file. When you export your file, MatNWB checks that:

- All required properties are present
- Data types match what the schema expects  
- Relationships between different parts of the file are correct

If anything is missing or incorrect, you'll get an error message explaining what needs to be fixed. This validation helps ensure your files will work with other NWB tools and can be understood by other researchers.

.. toctree::
    :maxdepth: 1
    :titlesonly:

    Understanding the NwbFile Object <file_create/nwbfile>
    Understanding Neurodata Types <file_create/neurodata_types>
    HDF5 Considerations <file_create/hdf5_considerations>
    Performance Optimization <file_create/performance_optimization>
