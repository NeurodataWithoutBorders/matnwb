Creating NWB Files
==================

When creating an NWB file, you're translating your experimental data and metadata into a structure that follows the NWB schema. MatNWB provides MATLAB classes that represent the different components (neurodata types) of an NWB file, allowing you to build up the file piece by piece.

To understand the structure of an NWB file, the NWB Overview documentation has a 
:nwb-overview:`great introduction <intro_to_nwb/2_file_structure.html>`.

As demonstrated in the quickstart tutorial, you start by creating an :class:`NwbFile` object.

.. note::
    An "object" is an instance of a class. Objects are similar to MATLAB structs, but with additional functionality. The fields (called properties) are defined by the class, and the class can enforce rules about what values are allowed. This helps ensure that your data conforms to the NWB schema.

When you create an :class:`NwbFile` object, you get a container whose properties are derived directly from the NWB schema. Some properties are required, others are optional. Some need specific MATLAB types like `char` or `datetime`, while others need specific neurodata types defined in the schema.

The Assembly Process
--------------------

Building an NWB file follows a logical pattern:

**Data Objects**: You create objects for your data (like :class:`types.core.TimeSeries` for time-based measurements)

**Container Object**: You add these data objects to your :class:`NwbFile` object in appropriate locations

**File Export**: You save everything to disk using :func:`nwbExport`, which translates your objects into NWB/HDF5 format

This approach ensures your data is properly organized and validated before it becomes a file.

Schema Validation
-----------------

The NWB schema acts as a blueprint that defines what makes a valid neuroscience data file. When you export your file, MatNWB checks that:

- All required properties are present
- Data types match what the schema expects  
- Relationships between different parts of the file are correct

If anything is missing or incorrect, you'll get an error message explaining what needs to be fixed. This validation helps ensure your files will work with other NWB tools and can be understood by other researchers.
