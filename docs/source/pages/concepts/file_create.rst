Creating NWB Files
==================

This section provides a guide to creating NWB (Neurodata Without Borders) files with MatNWB. It covers the fundamental concepts, step-by-step workflow, and important considerations when building NWB files from scratch. For detailed code examples and usage demonstrations, please refer to the :doc:`tutorials <../tutorials/index>`.

Creating an NWB file involves three main steps:

1. **Create an NwbFile object** with required metadata
2. **Add neurodata types** (time series, processed data, etc.)
3. **Export the file** using the :func:`nwbExport` function

**Example:**

.. code-block:: MATLAB

    % Step 1: Create NwbFile object
    nwb = NwbFile( ...
        'session_start_time', datetime('now', 'TimeZone', 'local'), ...
        'identifier', 'unique_session_id', ...
        'session_description', 'Description of your experiment');
    
    % Step 2: Add data (example: time series data)
    data = randn(1000, 10); % Example neural data
    timeseries = types.core.TimeSeries( ...
        'data', data, ...
        'data_unit', 'volts', ...
        'starting_time', 0.0, ...
        'starting_time_rate', 30000.0);
    nwb.acquisition.set('neural_data', timeseries);
    
    % Step 3: Export to file
    nwbExport(nwb, 'my_experiment.nwb');

.. note::
    After export the file, it is recommended to use the NWBInspector for comprehensive validation of both structural compliance with the NWB schema and compliance of data with NWB best practices. See :func:`inspectNwbFile`.

When creating an NWB file, it is useful to understand both its structure and the underlying HDF5 format. The :ref:`next section<matnwb-create-nwbfile-intro>` covers the NwbFile object and its configuration; later sections address data organization, performance, and important caveats about the HDF5 format.

.. warning::
    **Important HDF5 Limitations**
    
    NWB files are stored in HDF5 format, which has important limitations:
    
    - **To modify datasets** after creation - a DataPipe must be configured for the dataset on creation.
    - **Datasets should not be deleted** once created - the space will not be reclaimed.
    - **Schema consistency** must be maintained throughout the file creation process.

    See :doc:`file_create/hdf5_considerations` for detailed information on working within these constraints.

**Next steps**

The following pages provide detailed information on specific aspects of creating NWB files:

.. toctree::
    :maxdepth: 1

    file_create/nwbfile
    file_create/data_organization
    file_create/hdf5_considerations
    file_create/performance_optimization
