Data Organization in NWB Files
==============================

Once you have created an :class:`NwbFile` object, the next step is adding your experimental data using appropriate NWB data types. The NWB format provides a standardized structure for different types of neuroscience data.

Data Organization Hierarchy
---------------------------

NWB files organize data into several main categories:

- **acquisition** - Raw, unprocessed data from the experiment
- **processing** - Processed/analyzed data, organized by processing modules  
- **stimulus** - Information about experimental stimuli
- **analysis** - Custom analysis results
- **scratch** - Temporary storage during analysis

.. code-block:: MATLAB

    % Example of the basic structure
    nwb.acquisition.set('RawEphys', electrical_series);
    nwb.processing.set('EphysModule', processing_module);
    nwb.stimulus_presentation.set('VisualStimulus', image_series);

Adding Data with the .set Method
---------------------------------

NWB data containers (like ``acquisition``, ``processing``, etc.) use the ``.set`` method to add data objects. This method requires two arguments:

1. **Name** (string) - A unique identifier for the data object within that container
2. **Data Object** - The NWB data type being added (e.g., TimeSeries, ProcessingModule)

.. code-block:: MATLAB

    % The .set method syntax:
    nwb.acquisition.set('DataName', data_object);
    
    % Why .set is used instead of direct assignment:
    % This allows NWB to maintain internal structure and validate data types

**Naming Conventions:**

Use valid MATLAB identifiers with PascalCase for consistency:

.. code-block:: MATLAB

    % Good naming examples (PascalCase, descriptive):
    nwb.acquisition.set('RawElectricalSeries', electrical_series);
    nwb.acquisition.set('CalciumImagingData', two_photon_series);
    nwb.acquisition.set('BehaviorVideo', image_series);
    
    % Avoid these naming patterns:
    nwb.acquisition.set('data1', electrical_series);           % Not descriptive
    nwb.acquisition.set('raw-ephys', electrical_series);       % Invalid MATLAB identifier
    nwb.acquisition.set('raw_ephys_data', electrical_series);  % Use PascalCase instead

- **Use PascalCase** - capitalize the first letter of each word
- **Be descriptive** - names should indicate the data content and type
- **Avoid special characters** - stick to letters, numbers, and underscores if needed
- **Use valid MATLAB identifiers** - names that could be valid variable names
- **Be consistent** - establish and follow naming patterns within your lab/project

Refer to the :nwbinspector:`Naming Conventions <best_practices/best_practices_index.html>` section of the NWB Inspector docs for more details.


Time Series Data
----------------

Most neural data is time-varying and should use :class:`TimeSeries` objects or their specialized subclasses:

**Basic TimeSeries:**

.. code-block:: MATLAB

    % Generic time series data
    data = randn(5, 1000);  %  5 channels, 1000 time points
    
    ts = types.core.TimeSeries( ...
        'data', data, ...
        'data_unit', 'arbitrary_units', ...
        'starting_time', 0.0, ...
        'starting_time_rate', 1000.0, ...  % 1kHz sampling rate
        'description', 'Raw neural signal');
    
    nwb.acquisition.set('RawSignal', ts);

**Electrophysiology Data:**

For extracellular recordings, use :class:`ElectricalSeries`:

.. code-block:: MATLAB

    % Create electrode table (describes recording channels)
    electrode_table = util.createElectrodeTable(nwb, electrode_info);
    
    % Create reference to specific electrodes  
    electrode_region = types.hdmf_common.DynamicTableRegion( ...
        'table', types.untyped.ObjectView(electrode_table), ...
        'description', 'recording electrodes', ...
        'data', [0, 1, 2, 3]);  % Which electrodes were used
    
    % Raw extracellular data
    raw_data = int16(randn(30000, 4) * 1000);  % 1 second at 30kHz, 4 channels
    
    electrical_series = types.core.ElectricalSeries( ...
        'data', raw_data, ...
        'data_unit', 'microvolts', ...
        'electrodes', electrode_region, ...
        'starting_time', 0.0, ...
        'starting_time_rate', 30000.0);
    
    nwb.acquisition.set('RawEphys', electrical_series);

**Calcium Imaging Data:**

For optical data, use :class:`TwoPhotonSeries` or :class:`OnePhotonSeries`:

.. code-block:: MATLAB

    % First define imaging plane
    imaging_plane = types.core.ImagingPlane( ...
        'description', 'Primary visual cortex, layer 2/3', ...
        'excitation_lambda', 925.0, ...  % Two-photon excitation wavelength
        'imaging_rate', 30.0, ...
        'indicator', 'GCaMP6f', ...
        'location', 'V1');
    
    nwb.general_optophysiology.set('ImagingPlane1', imaging_plane);
    
    % Calcium imaging time series
    imaging_data = uint16(randn(50, 50, 1000) * 1000 + 2000);  % 50x50 pixels, 1000 frames
    
    two_photon_series = types.core.TwoPhotonSeries( ...
        'data', imaging_data, ...
        'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
        'starting_time', 0.0, ...
        'starting_time_rate', 30.0, ...
        'data_unit', 'fluorescence');
    
    nwb.acquisition.set('CalciumImaging', two_photon_series);

Processing Modules
------------------

Processed data should be organized into processing modules, which group related analyses together:

.. code-block:: MATLAB

    % Create a processing module for extracellular ephys
    ephys_module = types.core.ProcessingModule( ...
        'description', 'Processed extracellular electrophysiology data');
    
    % Add LFP data to the module
    lfp_data = randn(1000, 4);  % Downsampled/filtered data
    
    lfp_electrical_series = types.core.ElectricalSeries( ...
        'data', lfp_data, ...
        'data_unit', 'microvolts', ...
        'electrodes', electrode_region, ...
        'starting_time', 0.0, ...
        'starting_time_rate', 1000.0);  % 1kHz for LFP
    
    lfp = types.core.LFP();
    lfp.electricalseries.set('LFP', lfp_electrical_series);
    
    ephys_module.nwbdatainterface.set('LFP', lfp);
    nwb.processing.set('Ecephys', ephys_module);

Spike Data and Units
--------------------

Spike times and sorted units use the specialized :class:`Units` table:

.. code-block:: MATLAB

    % Create a Units table for spike data
    units_table = types.core.Units( ...
        'colnames', {'spike_times'}, ...
        'description', 'Sorted single units');
    
    % Add spike times for each unit
    unit1_spikes = [0.1, 0.5, 1.2, 1.8, 2.3];  % Spike times in seconds
    unit2_spikes = [0.3, 0.9, 1.5, 2.1, 2.7];
    
    units_table.addRow('spike_times', unit1_spikes);
    units_table.addRow('spike_times', unit2_spikes);
    
    nwb.units = units_table;

Behavioral Data
---------------

Behavioral measurements can be stored as :class:`TimeSeries` or in specialized containers:

.. code-block:: MATLAB

    % Position tracking
    position_data = randn(1000, 2);  % X, Y coordinates over time
    
    spatial_series = types.core.SpatialSeries( ...
        'data', position_data, ...
        'reference_frame', 'Arena coordinates (cm)', ...
        'data_unit', 'cm', ...
        'starting_time', 0.0, ...
        'starting_time_rate', 60.0);  % 60 Hz tracking
    
    position = types.core.Position();
    position.spatialseries.set('Position', spatial_series);
    
    % Add to a behavior processing module
    behavior_module = types.core.ProcessingModule( ...
        'description', 'Behavioral data processing');
    behavior_module.nwbdatainterface.set('Position', position);
    nwb.processing.set('Behavior', behavior_module);

Trial Structure
---------------

Experimental trials are stored in the intervals table:

.. code-block:: MATLAB

    % Create trials table
    trials = types.core.TimeIntervals( ...
        'colnames', {'start_time', 'stop_time', 'stimulus_type', 'response'}, ...
        'description', 'Experimental trials');
    
    % Add individual trials
    trials.addRow( ...
        'start_time', 0.0, ...
        'stop_time', 2.0, ...
        'stimulus_type', 'left_grating', ...
        'response', 'correct');
    
    trials.addRow( ...
        'start_time', 5.0, ...
        'stop_time', 7.0, ...
        'stimulus_type', 'right_grating', ...
        'response', 'incorrect');
    
    nwb.intervals_trials = trials;

Large Dataset Considerations
----------------------------

For large datasets, consider using :class:`types.untyped.DataPipe` for compression and chunking:

.. code-block:: MATLAB

    % Large imaging dataset with compression
    large_imaging_data = uint16(randn(512, 512, 10000) * 1000);
    
    compressed_data = types.untyped.DataPipe( ...
        'data', large_imaging_data, ...
        'compressionLevel', 6, ...
        'chunkSize', [512, 512, 1]);  % Chunk by frame
    
    two_photon_series = types.core.TwoPhotonSeries( ...
        'data', compressed_data, ...
        'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
        'starting_time', 0.0, ...
        'starting_time_rate', 30.0, ...
        'data_unit', 'fluorescence');

See :doc:`performance_optimization` for detailed information on handling large datasets efficiently.


Validation and Consistency
--------------------------

Key principles for data organization:

1. **Use appropriate data types** - don't store imaging data as generic TimeSeries
2. **Maintain consistent units** - ensure all related data uses the same time base
3. **Document your choices** - use descriptive names and fill in description fields

.. code-block:: MATLAB

    % Good practice: descriptive names and consistent units
    nwb.acquisition.set('RawExtracellularV1', electrical_series);
    nwb.acquisition.set('CalciumImagingV1L23', two_photon_series);
    
    % Bad practice: generic names, unclear relationships  
    nwb.acquisition.set('Data1', electrical_series);
    nwb.acquisition.set('Data2', two_photon_series);

Next Steps
----------

With your data properly organized, the next considerations are performance optimization and understanding HDF5 constraints that affect how you structure your file creation workflow.
