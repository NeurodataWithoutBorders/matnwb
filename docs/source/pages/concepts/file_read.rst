Reading NWB Files
=================

This section provides an overview of reading and exploring NWB (Neurodata Without Borders) files with MatNWB. It serves as a reference guide to the functions and data objects you’ll interact with when working with NWB files. For detailed code examples and usage demonstrations, please refer to the :doc:`tutorials <../tutorials/index>`.

To read an NWB file, use the :func:`nwbRead` function:

.. code-block:: MATLAB

    nwb = nwbRead('path/to/file.nwb');

This command performs several important tasks behind the scenes:

1. **Opens the file** and reads its structure  
2. **Automatically generates MATLAB classes** needed to work with the data  
3. **Returns an NwbFile object** representing the entire file  

The returned :class:`NwbFile` object is the primary access point for all the data in the file. In the :ref:`next section<matnwb-read-nwbfile-intro>`, we will examine the structure of this object in detail, covering how to explore it using standard MATLAB dot notation to access experimental metadata, raw recordings, processed data, and analysis results, as well as how to search for specific data types.

.. important::
    **Lazy Loading:** MatNWB uses lazy reading to efficiently work with large datasets. When you access a dataset through the `NwbFile` object, MatNWB returns a :class:`types.untyped.DataStub` object instead of loading the entire dataset into memory. This allows you to:
    
    - Work with files larger than available RAM
    - Read only the portions of data you need
    - Index into datasets using standard MATLAB array syntax
    - Load the full dataset explicitly using the ``.load()`` method
    
    For more details, see :ref:`DataStubs and DataPipes<matnwb-read-untyped-datastub-datapipe>`.

.. note::
    The :func:`nwbRead` function currently does not support reading NWB files stored in Zarr format.

**Next steps**

The following pages provide detailed information on specific aspects of reading NWB files:

.. toctree::
    :maxdepth: 1

    file_read/nwbfile
    file_read/dynamictable
    file_read/untyped
    file_read/schemas_and_generation
    file_read/troubleshooting
