.. _ecephys-tutorial:

Extracellular Electrophysiology 🎬
==================================

.. image:: https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg
   :target: https://matlab.mathworks.com/open/github/v1?repo=NeurodataWithoutBorders/matnwb&file=tutorials/ecephys.mlx
   :alt: Open in MATLAB Online
.. image:: https://img.shields.io/badge/View-Rendered_Live_Script-blue
   :target: ../../_static/html/tutorials/ecephys.html
   :alt: View rendered Live Script
.. image:: https://img.shields.io/badge/View-Youtube-red
   :target: https://www.youtube.com/watch?v=W8t4_quIl1k&ab_channel=NeurodataWithoutBorders
   :alt: View tutorial on YouTube

.. contents:: On this page
   :local:
   :depth: 2

About This Tutorial
-------------------

This tutorial describes storage of hypothetical data from extracellular electrophysiology experiments in NWB for the following data categories:

* Raw voltage recording
* Local field potential (LFP) and filtered electrical signals
* Spike times

Before You Begin
----------------

It is recommended to first work through the `Introduction to MatNWB tutorial <intro>`_, which demonstrates installing MatNWB and creating an NWB file with subject information, animal position, and trials, as well as writing and reading NWB files in MATLAB.

**Important**: The dimensions of timeseries data in MatNWB should be defined in the opposite order of how it is defined in the nwb-schemas. In NWB, time is always stored in the first dimension of the data, whereas in MatNWB time should be stored in the last dimension of the data. This is explained in more detail here: `MatNWB <-> HDF5 Dimension Mapping <dimensionMapNoDataPipes>`_.

Setting up the NWB File
-----------------------

An NWB file represents a single session of an experiment. Each file must have a ``session_description``, ``identifier``, and ``session_start_time``. Create a new `NWBFile <https://matnwb.readthedocs.io/en/latest/pages/functions/NwbFile.html>`_ object these required fields along with any additional metadata. In MatNWB, arguments are specified using MATLAB's keyword argument pair convention, where each argument name is followed by its value.

.. code-block:: matlab

   nwb = NwbFile( ...
       'session_description', 'mouse in open exploration',...
       'identifier', 'Mouse5_Day3', ...
       'session_start_time', datetime(2018, 4, 25, 2, 30, 3, 'TimeZone', 'local'), ...
       'timestamps_reference_time', datetime(2018, 4, 25, 3, 0, 45, 'TimeZone', 'local'), ...
       'general_experimenter', 'Last Name, First Name', ... % optional
       'general_session_id', 'session_1234', ... % optional
       'general_institution', 'University of My Institution', ... % optional
       'general_related_publications', {'DOI:10.1016/j.neuron.2016.12.011'}); % optional
   nwb

.. code-block:: text

   nwb = 
     NwbFile with properties:
   
                                                nwb_version: '2.9.0'
                                           file_create_date: []
                                                 identifier: 'Mouse5_Day3'
                                        session_description: 'mouse in open exploration'
                                         session_start_time: {[2018-04-25T02:30:03.000000+02:00]}
                                  timestamps_reference_time: {[2018-04-25T03:00:45.000000+02:00]}
                                                acquisition: [0x1 types.untyped.Set]
                                                   analysis: [0x1 types.untyped.Set]
                                                    general: [0x1 types.untyped.Set]
                                    general_data_collection: ''
                                            general_devices: [0x1 types.untyped.Set]
                                     general_devices_models: [0x1 types.untyped.Set]
                             general_experiment_description: ''
                                       general_experimenter: 'Last Name, First Name'
                                general_extracellular_ephys: [0x1 types.untyped.Set]
                     general_extracellular_ephys_electrodes: []
                                        general_institution: 'University of My Institution'
                                general_intracellular_ephys: [0x1 types.untyped.Set]
        general_intracellular_ephys_experimental_conditions: []
                      general_intracellular_ephys_filtering: ''
       general_intracellular_ephys_intracellular_recordings: []
                    general_intracellular_ephys_repetitions: []
          general_intracellular_ephys_sequential_recordings: []
        general_intracellular_ephys_simultaneous_recordings: []
                    general_intracellular_ephys_sweep_table: []
                                           general_keywords: ''
                                                general_lab: ''
                                              general_notes: ''
                                       general_optogenetics: [0x1 types.untyped.Set]
                                     general_optophysiology: [0x1 types.untyped.Set]
                                       general_pharmacology: ''
                                           general_protocol: ''
                               general_related_publications: {'DOI:10.1016/j.neuron.2016.12.011'}
                                         general_session_id: 'session_1234'
                                             general_slices: ''
                                      general_source_script: ''
                            general_source_script_file_name: ''
                                           general_stimulus: ''
                                            general_subject: []
                                            general_surgery: ''
                                              general_virus: ''
                                   general_was_generated_by: ''
                                                  intervals: [0x1 types.untyped.Set]
                                           intervals_epochs: []
                                    intervals_invalid_times: []
                                           intervals_trials: []
                                                 processing: [0x1 types.untyped.Set]
                                                    scratch: [0x1 types.untyped.Set]
                                      stimulus_presentation: [0x1 types.untyped.Set]
                                         stimulus_templates: [0x1 types.untyped.Set]
                                                      units: []

Subject Information
~~~~~~~~~~~~~~~~~~~

It is also recommended to store information about the experimental subject in the file. Create a `Subject <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Subject.html>`_ object to store metadata about the subject, then assign it to ``nwb.general_subject``.

.. code-block:: matlab

   subject = types.core.Subject( ...
       'subject_id', '005', ...
       'age', 'P90D', ...
       'description', 'mouse 5', ...
       'species', 'Mus musculus', ...
       'sex', 'M' ...
   );
   nwb.general_subject = subject;

Electrode Information
---------------------

In order to store extracellular electrophysiology data, you first must create an electrodes table describing the electrodes that generated this data. Extracellular electrodes are stored in an ``electrodes`` table, which is also a `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_. ``electrodes`` has several required fields: ``x``, ``y``, ``z``, ``impedance``, ``location``, ``filtering``, and ``electrode_group``.

The electrodes table references a required `ElectrodeGroup <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ElectrodeGroup.html>`_, which is used to represent a group of electrodes. Before creating an `ElectrodeGroup <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ElectrodeGroup.html>`_, you must define a `Device <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Device.html>`_ object. The fields ``description``, ``serial_number`` and ``model`` are optional, but recommended. The ``model`` property can contain a `DeviceModel <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/DeviceModel.html>`_ object which stores information about the device model. This property can be useful when searching a set of NWB files or a data archive for all files that use a specific device model (e.g., Neuropixels probe).

.. code-block:: matlab

   device_model = types.core.DeviceModel( ...
        'manufacturer', 'Array Technologies', ...
        'model_number', 'PRB_1_4_0480_123', ...
        'description', 'Neurovoxels 0.99 - A 12-channel array with 4 shanks and 3 channels per shank' ...
   );
   % Add device model to nwb object
   nwb.general_devices_models.set('Neurovoxels 0.99', device_model);

.. code-block:: matlab

   
   device = types.core.Device(...
       'description', 'A 12-channel array with 4 shanks and 3 channels per shank', ...
       'serial_number', '1234567890', ...
       'model', device_model ...
   );
   
   % Add device to nwb object
   nwb.general_devices.set('array', device);

Electrodes Table
~~~~~~~~~~~~~~~~

.. image:: ../../_static/tutorials/media/ecephys/image_0.png
   :class: tutorial-media
   :width: 576px
   :alt: image_0.png

Since this is a `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_, we can add additional metadata fields. We will be adding a "label" column to the table.

.. code-block:: matlab

   numShanks = 4;
   numChannelsPerShank = 3;
   numChannels = numShanks * numChannelsPerShank;
   
   electrodesDynamicTable = types.core.ElectrodesTable(...
       'colnames', {'location', 'group', 'group_name', 'label'}, ...
       'description', 'all electrodes');
   
   for iShank = 1:numShanks
       shankGroupName = sprintf('shank%d', iShank);
       electrodeGroup = types.core.ElectrodeGroup( ...
           'description', sprintf('electrode group for %s', shankGroupName), ...
           'location', 'brain area', ...
           'device', types.untyped.SoftLink(device) ...
       );
       
       nwb.general_extracellular_ephys.set(shankGroupName, electrodeGroup);
       for iElectrode = 1:numChannelsPerShank
           electrodesDynamicTable.addRow( ...
               'location', 'Primary visual area', ...
               'group', types.untyped.ObjectView(electrodeGroup), ...
               'group_name', shankGroupName, ...
               'label', sprintf('%s-electrode%d', shankGroupName, iElectrode));
       end
   end
   electrodesDynamicTable.toTable() % Display the table

.. list-table::
   :header-rows: 1

   * - 
     - id
     - location
     - group
     - group_name
     - label
   * - 1
     - 0
     - 'Primary visual area'
     - 1x1 ObjectView
     - 'shank1'
     - 'shank1-electrode1'
   * - 2
     - 1
     - 'Primary visual area'
     - 1x1 ObjectView
     - 'shank1'
     - 'shank1-electrode2'
   * - 3
     - 2
     - 'Primary visual area'
     - 1x1 ObjectView
     - 'shank1'
     - 'shank1-electrode3'
   * - 4
     - 3
     - 'Primary visual area'
     - 1x1 ObjectView
     - 'shank2'
     - 'shank2-electrode1'
   * - 5
     - 4
     - 'Primary visual area'
     - 1x1 ObjectView
     - 'shank2'
     - 'shank2-electrode2'
   * - 6
     - 5
     - 'Primary visual area'
     - 1x1 ObjectView
     - 'shank2'
     - 'shank2-electrode3'
   * - 7
     - 6
     - 'Primary visual area'
     - 1x1 ObjectView
     - 'shank3'
     - 'shank3-electrode1'
   * - 8
     - 7
     - 'Primary visual area'
     - 1x1 ObjectView
     - 'shank3'
     - 'shank3-electrode2'
   * - 9
     - 8
     - 'Primary visual area'
     - 1x1 ObjectView
     - 'shank3'
     - 'shank3-electrode3'
   * - 10
     - 9
     - 'Primary visual area'
     - 1x1 ObjectView
     - 'shank4'
     - 'shank4-electrode1'
   * - 11
     - 10
     - 'Primary visual area'
     - 1x1 ObjectView
     - 'shank4'
     - 'shank4-electrode2'
   * - 12
     - 11
     - 'Primary visual area'
     - 1x1 ObjectView
     - 'shank4'
     - 'shank4-electrode3'

.. code-block:: matlab

   nwb.general_extracellular_ephys_electrodes = electrodesDynamicTable;

Links
~~~~~

In the above loop, we create `ElectrodeGroup <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ElectrodeGroup.html>`_ objects. The ``electrodes`` table then uses an ``ObjectView`` in each row to link to the corresponding `ElectrodeGroup <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ElectrodeGroup.html>`_ object. An ``ObjectView`` is a construct that enables linking one neurodata type to another, allowing a neurodata type to reference another within the NWB file.

Recorded Extracellular Signals
------------------------------

Voltage data are stored using the `ElectricalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ElectricalSeries.html>`_ class, a subclass of the `TimeSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeSeries.html>`_ class specialized for voltage data.

Referencing Electrodes
~~~~~~~~~~~~~~~~~~~~~~

In order to create our `ElectricalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ElectricalSeries.html>`_ object, we first need to reference a set of rows in the ``electrodes`` table to indicate which electrode (channel) each entry in the electrical series were recorded from. We will do this by creating a `DynamicTableRegion <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTableRegion.html>`_, which is a type of link that allows you to reference specific rows of a `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_, such as the ``electrodes`` table, using row indices.

Create a `DynamicTableRegion <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTableRegion.html>`_ that references all rows of the ``electrodes`` table.

.. code-block:: matlab

   electrode_table_region = types.hdmf_common.DynamicTableRegion( ...
       'table', types.untyped.ObjectView(electrodesDynamicTable), ...
       'description', 'all electrodes', ...
       'data', (0:length(electrodesDynamicTable.id.data)-1)');

Raw Voltage Data
~~~~~~~~~~~~~~~~

Now create an `ElectricalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ElectricalSeries.html>`_ object to hold acquisition data collected during the experiment.

.. image:: ../../_static/tutorials/media/ecephys/image_1.png
   :class: tutorial-media
   :width: 840px
   :alt: image_1.png

.. code-block:: matlab

   raw_electrical_series = types.core.ElectricalSeries( ...
       'starting_time', 0.0, ... % seconds
       'starting_time_rate', 30000., ... % Hz
       'data', randn(numChannels, 3000), ... % nChannels x nTime
       'electrodes', electrode_table_region, ...
       'data_unit', 'volts');

This is the voltage data recorded directly from our electrodes, so it goes in the acquisition group.

.. code-block:: matlab

   nwb.acquisition.set('ElectricalSeries', raw_electrical_series);

Processed Extracellular Electrical Signals
------------------------------------------

LFP
~~~

LFP refers to data that has been low-pass filtered, typically below 300 Hz. This data may also be downsampled. Because it is filtered and potentially resampled, it is categorized as processed data. LFP data would also be stored in an `ElectricalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ElectricalSeries.html>`_. To help data analysis and visualization tools know that this `ElectricalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ElectricalSeries.html>`_ object represents LFP data, we store it inside an `LFP <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/LFP.html>`_ object and then place the `LFP <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/LFP.html>`_ object in a `ProcessingModule <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ProcessingModule.html>`_ named ``'ecephys'``. This is analogous to how we stored the `SpatialSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/SpatialSeries.html>`_ object inside of a `Position <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Position.html>`_ object and stored the `Position <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Position.html>`_ object in a `ProcessingModule <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ProcessingModule.html>`_ named ``'behavior'`` in the `behavior <behavior>`_ tutorial

.. image:: ../../_static/tutorials/media/ecephys/image_2.png
   :class: tutorial-media
   :width: 1311px
   :alt: image_2.png

.. code-block:: matlab

   lfp_electrical_series = types.core.ElectricalSeries( ...
       'starting_time', 0.0, ... % seconds
       'starting_time_rate', 1000., ... % Hz
       'data', randn(numChannels, 100), ... nChannels x nTime
       'filtering', 'Low-pass filter at 300 Hz', ...
       'electrodes', electrode_table_region, ...
       'data_unit', 'volts');
   
   lfp = types.core.LFP('ElectricalSeries', lfp_electrical_series);
   
   ecephys_module = types.core.ProcessingModule(...
       'description', 'extracellular electrophysiology');
   
   ecephys_module.nwbdatainterface.set('LFP', lfp);
   nwb.processing.set('ecephys', ecephys_module);

Other Types of Filtered Electrical Signals
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If your acquired data is filtered for frequency ranges other than LFP—such as Gamma or Theta—you can store the result in an `ElectricalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ElectricalSeries.html>`_ and encapsulate it within a `FilteredEphys <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/FilteredEphys.html>`_ object instead of the `LFP <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/LFP.html>`_ object.

.. code-block:: matlab

   % Generate filtered data
   filtered_data = randn(50, 12); % 50 time points, 12 channels
   filtered_data = permute(filtered_data, [2, 1]); % permute timeseries for matnwb
   
   % Create an ElectricalSeries object
   filtered_electrical_series = types.core.ElectricalSeries( ...
       'description', 'Data filtered in the theta range', ...
       'data', filtered_data, ...
       'electrodes', electrode_table_region, ...
       'filtering', 'Band-pass filtered between 4 and 8 Hz', ...
       'starting_time', 0.0, ...
       'starting_time_rate', 200.0 ...
       );
   
   % Create a FilteredEphys object and add the filtered electrical series
   filtered_ephys = types.core.FilteredEphys();
   filtered_ephys.electricalseries.set('FilteredElectricalSeries', filtered_electrical_series);
   
   % Add the FilteredEphys object to the ecephys module
   ecephys_module.nwbdatainterface.set('FilteredEphys', filtered_ephys);

Decomposition of LFP Data into Frequency Bands
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In some cases, you may want to further process the LFP data and decompose the signal into different frequency bands for additional downstream analyses. You can then store the processed data from these spectral analyses using a `DecompositionSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/DecompositionSeries.html>`_ object. This object allows you to include metadata about the frequency bands and metric used (e.g., ``power``, ``phase``, ``amplitude``), as well as link the decomposed data to the original `TimeSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeSeries.html>`_ signal the data was derived from.

In this tutorial, the examples for `FilteredEphys <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/FilteredEphys.html>`_ and `DecompositionSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/DecompositionSeries.html>`_ may appear similar. However, the key difference is that `DecompositionSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/DecompositionSeries.html>`_ is specialized for storing the results of spectral analyses of timeseries data in general, whereas `FilteredEphys <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/FilteredEphys.html>`_ is defined specifically as a container for filtered electrical signals.

**Note**: When adding data to a `DecompositionSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/DecompositionSeries.html>`_, the ``data`` argument is assumed to be 3D where the first dimension is time, the second dimension is channels, and the third dimension is bands. As mentioned in the beginning of this tutorial, in MatNWB the data needs to be permuted because the dimensions are written to file in reverse order (See the `dimensionMapNoDataPipes <dimensionMapNoDataPipes>`_ tutorial)

.. code-block:: matlab

   % Define the frequency bands of interest (in Hz):
   band_names = {'theta'; 'beta'; 'gamma'};
   band_mean = [8; 21; 55];
   band_stdev = [2; 4.5; 12.5];
   band_limits = [band_mean - 2*band_stdev, band_mean + 2*band_stdev];
   
   % The bands should be added to the DecompositionSeries as a dynamic table
   bands = table(band_names, band_mean, band_stdev, band_limits, ...
       'VariableNames', {'band_name', 'band_mean', 'band_stdev', 'band_limits'})

.. list-table::
   :header-rows: 1

   * - 
     - band_name
     - band_mean
     - band_stdev
     - band_limits
     - 
   * - 
     - 
     - 
     - 
     - 1
     - 2
   * - 1
     - 'theta'
     - 8
     - 2
     - 4
     - 12
   * - 2
     - 'beta'
     - 21
     - 4.5000
     - 12
     - 30
   * - 3
     - 'gamma'
     - 55
     - 12.5000
     - 30
     - 80

.. code-block:: matlab

   bands = util.table2nwb( bands, 'Frequency bands for lfp', 'types.core.FrequencyBandsTable');
   
   % Generate random phase data for the demonstration.
   phase_data = randn(50, 12, numel(band_names)); % 50 samples, 12 channels, 3 frequency bands
   phase_data = permute(phase_data, [3,2,1]); % See dimensionMapNoDataPipes tutorial
   
   decomp_series = types.core.DecompositionSeries(...
       'data', phase_data, ...
       'bands', bands, ...
       'metric', 'phase', ...
       'starting_time', 0.0, ... % seconds
       'starting_time_rate', 1000.0, ... % Hz
       'source_channels', electrode_table_region, ...
       'source_timeseries', lfp_electrical_series);
   
   % Add decomposition series to ecephys module
   ecephys_module.nwbdatainterface.set('theta', decomp_series);

Spike Times and Extracellular Events
------------------------------------

Sorted Spike Times
~~~~~~~~~~~~~~~~~~

Spike times are stored in a `Units <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Units.html>`_ table, a specialization of the `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ class. The default `Units <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Units.html>`_ table is located at ``/units`` in the HDF5 file. You can add columns to the `Units <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Units.html>`_ table just like you did for ``electrodes`` and ``trials`` (see `convertTrials <convertTrials>`_). Here, we generate some random spike time data and populate the table. Note: Spike times of a `Units <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Units.html>`_ table should be sorted in ascending order.

.. code-block:: matlab

   num_cells = 10;
   spike_times = cell(1, num_cells);
   for iShank = 1:num_cells
       spike_times{iShank} = sort( rand(1, randi([16, 28])), 'ascend');
   end
   spike_times

.. list-table::
   :header-rows: 1

   * - 
     - 1
     - 2
     - 3
     - 4
     - 5
     - 6
     - 7
     - 8
     - 9
     - 10
   * - 1
     - 1x28 double
     - 1x18 double
     - 1x28 double
     - 1x24 double
     - 1x16 double
     - 1x23 double
     - 1x25 double
     - 1x24 double
     - 1x19 double
     - 1x21 double

Ragged Arrays
^^^^^^^^^^^^^

Spike times are an example of a ragged array- it's like a matrix, but each row has a different number of elements. We can represent this type of data as an indexed column of the `Units <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Units.html>`_ table. These indexed columns have two components, the `VectorData <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/VectorData.html>`_ object that holds the data and the `VectorIndex <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/VectorIndex.html>`_ object that holds the indices in the vector that indicate the row breaks. You can use the convenience function ``util.create_indexed_column`` to create these objects. For more information about ragged arrays, we refer you to the **"Ragged Array Columns"** section of the `dynamic table <dynamic_tables>`_ tutorial.

.. image:: ../../_static/tutorials/media/ecephys/image_3.png
   :class: tutorial-media
   :width: 703px
   :alt: image_3.png

.. code-block:: matlab

   [spike_times_vector, spike_times_index] = util.create_indexed_column(spike_times);
   spike_times_vector.resolution = 1/20000; % If original sampling rate was 20 kHz 
   
   nwb.units = types.core.Units( ...
       'colnames', {'spike_times'}, ...
       'description', 'units table', ...
       'spike_times', spike_times_vector, ...
       'spike_times_index', spike_times_index ...
   );
   
   nwb.units.toTable()

.. list-table::
   :header-rows: 1

   * - 
     - id
     - spike_times
   * - 1
     - 0
     - 28x1 double
   * - 2
     - 1
     - 18x1 double
   * - 3
     - 2
     - 28x1 double
   * - 4
     - 3
     - 24x1 double
   * - 5
     - 4
     - 16x1 double
   * - 6
     - 5
     - 23x1 double
   * - 7
     - 6
     - 25x1 double
   * - 8
     - 7
     - 24x1 double
   * - 9
     - 8
     - 19x1 double
   * - 10
     - 9
     - 21x1 double

Unsorted Spike Times
~~~~~~~~~~~~~~~~~~~~

While the `Units <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Units.html>`_ table is used to store spike times and waveform data for spike-sorted, single-unit activity, you may also want to store spike times and waveform snippets of unsorted spiking activity. This is useful for recording multi-unit activity detected via threshold crossings during data acquisition. Such information can be stored using `SpikeEventSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/SpikeEventSeries.html>`_ objects.

.. code-block:: matlab

   % In the SpikeEventSeries the dimensions should be ordered as 
   % [num_events, num_channels, num_samples].
   % Define spike snippets: 20 events, 3 channels, 40 samples per event. 
   spike_snippets = rand(20, 3, 40);
   % Permute spike snippets (See dimensionMapNoDataPipes tutorial)
   spike_snippets = permute(spike_snippets, [3,2,1]); 
   
   % Create electrode table region referencing electrodes 0, 1, and 2
   shank0_table_region = types.hdmf_common.DynamicTableRegion( ...
       'table', types.untyped.ObjectView(electrodesDynamicTable), ...
       'description', 'shank0', ...
       'data', (0:2)');
   
   % Define spike event series for unsorted spike times
   spike_events = types.core.SpikeEventSeries( ...
       'data', spike_snippets, ...
       'timestamps', (0:19)', ...  % Timestamps for each event
       'description', 'events detected with 100uV threshold', ...
       'electrodes', shank0_table_region ...
   );
   
   % Add spike event series to NWB file acquisition
   nwb.acquisition.set('SpikeEvents_Shank0', spike_events);

Detected Events
~~~~~~~~~~~~~~~

If you need to store the complete, continuous raw voltage traces, along with unsorted spike times, you should store the traces in `ElectricalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ElectricalSeries.html>`_ objects in the acquisition group, and use the `EventDetection <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/EventDetection.html>`_ class to identify the spike events in your raw traces.

.. code-block:: matlab

   % Create the EventDetection object
   event_detection = types.core.EventDetection( ...
       'detection_method', 'thresholding, 1.5 * std', ...
       'source_electricalseries', types.untyped.SoftLink(raw_electrical_series), ...
       'source_idx', [1000; 2000; 3000], ...
       'times', [.033, .066, .099] ...
   );
   
   % Add the EventDetection object to the ecephys module
   ecephys_module.nwbdatainterface.set('ThresholdEvents', event_detection);

Storing Spike Features (e.g Principal Components)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

NWB also provides a way to store features of spikes, such as principal components, using the `FeatureExtraction <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/FeatureExtraction.html>`_ class.

.. code-block:: matlab

   % Generate random feature data (time x channel x feature)
   features = rand(3, 12, 4); % 3 time points, 12 channels, 4 features
   features = permute(features, [3,2,1]); % reverse dimension order for matnwb
   
   % Create the FeatureExtraction object
   feature_extraction = types.core.FeatureExtraction( ...
       'description', {'PC1', 'PC2', 'PC3', 'PC4'}, ... % Feature descriptions
       'electrodes', electrode_table_region, ...
       'times', [.033; .066; .099], ... % Column vector for times
       'features', features ...
   );
   
   % Add the FeatureExtraction object to the ecephys module (if required)
   ecephys_module.nwbdatainterface.set('PCA_features', feature_extraction);

Choosing NWB-Types for Electrophysiology Data (A Summary)
---------------------------------------------------------

As mentioned above, `ElectricalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ElectricalSeries.html>`_ objects are meant for storing electrical timeseries data like raw voltage signals or processed signals like LFP or other filtered signals. In addition to the `ElectricalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ElectricalSeries.html>`_ class, NWB provides some more classes for storing event-based electropysiological data. We will briefly discuss them here, and refer the reader to the `API documentation <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/index.html>`_ and the section on `Extracellular Physiology <https://nwb-schema.readthedocs.io/en/latest/format.html#extracellular-electrophysiology>`_ in the "NWB Format Specification" for more details on using these objects.

For storing unsorted spiking data, there are two options. Which one you choose depends on what data you have available. If you need to store complete and/or continuous raw voltage traces, you should store the traces with `ElectricalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ElectricalSeries.html>`_ objects as acquisition data, and use the `EventDetection <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/EventDetection.html>`_ class for identifying the spike events in your raw traces. If you do not want to store the entire raw voltage traces, only the waveform ‘snippets’ surrounding spike events, you should use `SpikeEventSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/SpikeEventSeries.html>`_ objects.

The results of spike sorting (or clustering) should be stored in the top-level `Units <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Units.html>`_ table. The `Units <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Units.html>`_ table can hold just the spike times of sorted units or, optionally, include additional waveform information. You can use the optional predefined columns ``waveform_mean``, ``waveform_sd``, and ``waveforms`` in the `Units <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Units.html>`_ table to store individual and mean waveform data.

Writing the NWB File
--------------------

.. code-block:: matlab

   nwbExport(nwb, 'ecephys_tutorial.nwb')

Reading NWB Data
----------------

Data arrays are read passively from the file. Calling ``TimeSeries.data`` does not read the data values, but presents an HDF5 object that can be indexed to read data. This allows you to conveniently work with datasets that are too large to fit in RAM all at once. ``load`` with no input arguments reads the entire dataset:

.. code-block:: matlab

   nwb2 = nwbRead('ecephys_tutorial.nwb', 'ignorecache');
   nwb2.processing.get('ecephys'). ...
       nwbdatainterface.get('LFP'). ...
       electricalseries.get('ElectricalSeries'). ...
       data.load;

Accessing Data Regions
----------------------

If all you need is a data region, you can index a ``DataStub`` object like you would any normal array in MATLAB, as shown below. When indexing the dataset this way, only the selected region is read from disk into RAM. This allows you to handle very large datasets that would not fit entirely into RAM.

.. code-block:: matlab

   % read section of LFP
   nwb2.processing.get('ecephys'). ...
       nwbdatainterface.get('LFP'). ...
       electricalseries.get('ElectricalSeries'). ...
       data(1:5, 1:10)

.. code-block:: text

   ans = 5x10
      -0.7839    0.0147   -0.4823    0.7583    0.8135   -2.0957    0.9011   -2.3509    0.1892   -2.0754
       0.2895   -0.2133    0.5483   -1.4372   -0.0451   -1.1182   -1.9083    1.1331   -0.5946   -0.1609
      -0.9435    0.2274   -0.7730    0.2097   -0.3885    1.7777   -0.5676   -0.0386    0.4206    0.3531
      -0.4632    0.7073   -0.4644    0.3453    0.4681    0.4659    1.6279    2.0310   -0.5402   -0.8882
       0.3153    0.0440   -2.5588   -0.8699    0.6555    1.3090   -0.0109    0.4978    0.2622   -0.3127

.. code-block:: matlab

   
   % You can use the getRow method of the table to load spike times of a specific unit.
   % To get the values, unpack from the returned table.
   nwb.units.getRow(1).spike_times{1}

.. code-block:: text

   ans = 28x1
       0.0264
       0.0591
       0.0854
       0.1181
       0.1203
       0.1328
       0.1918
       0.2230
       0.2389
       0.2487

Learn more!
-----------

See the `API documentation <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/index.html>`_ to learn what data types are available.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

MATLAB tutorials
----------------

* `Optical physiology <ophys>`_
* `Intracellular electrophysiology <icephys>`_

Python tutorials
----------------

See our tutorials for more details about your data type:

* `Calcium imaging <https://pynwb.readthedocs.io/en/stable/tutorials/domain/ophys.html#sphx-glr-tutorials-domain-ophys-py>`_
* `Extracellular electrophysiology <https://pynwb.readthedocs.io/en/stable/tutorials/domain/ecephys.html#sphx-glr-tutorials-domain-ecephys-py>`_
* `Intracellular electrophysiology <https://pynwb.readthedocs.io/en/stable/tutorials/domain/plot_icephys.html#intracellular-electrophysiology>`_

**Check out other tutorials that teach advanced NWB topics:**

* `Iterative data write <https://pynwb.readthedocs.io/en/stable/tutorials/advanced_io/plot_iterative_write.html#sphx-glr-tutorials-advanced-io-plot-iterative-write-py>`_
* `Extensions <https://pynwb.readthedocs.io/en/stable/tutorials/general/extensions.html#sphx-glr-tutorials-general-extensions-py>`_
* `Advanced HDF5 I/O <https://pynwb.readthedocs.io/en/stable/tutorials/advanced_io/h5dataio.html#sphx-glr-tutorials-advanced-io-h5dataio-py>`_
