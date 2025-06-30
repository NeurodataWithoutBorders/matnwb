.. _matnwb-read-nwbfile-intro:

Working with the NwbFile Object
===============================

When you read an NWB file with ``nwbRead``, you get back an :class:`NwbFile` object that serves as the main interface to all the data in the file. 

NwbFile Example
---------------

For illustration, we'll run the ecephys tutorial and read the resulting NWB file:

.. code-block:: MATLAB

    evalc("run('tutorials/ecephys.mlx')"); % Run tutorial with suppressed output
    nwb = nwbRead('tutorials/ecephys_tutorial.nwb');
    disp(nwb)

.. code-block:: text

    
      NwbFile with properties:
    
                                                 nwb_version: '2.8.0'
                                            file_create_date: [1×1 types.untyped.DataStub]
                                                  identifier: 'Mouse5_Day3'
                                         session_description: 'mouse in open exploration'
                                          session_start_time: [1×1 types.untyped.DataStub]
                                   timestamps_reference_time: [1×1 types.untyped.DataStub]
                                                 acquisition: [2×1 types.untyped.Set]
                                                    analysis: [0×1 types.untyped.Set]
                                                     general: [0×1 types.untyped.Set]
                                     general_data_collection: ''
                                             general_devices: [1×1 types.untyped.Set]
                              general_experiment_description: ''
                                        general_experimenter: [1×1 types.untyped.DataStub]
                                 general_extracellular_ephys: [4×1 types.untyped.Set]
                      general_extracellular_ephys_electrodes: [1×1 types.hdmf_common.DynamicTable]
                                         general_institution: 'University of My Institution'
                                 general_intracellular_ephys: [0×1 types.untyped.Set]
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
                                        general_optogenetics: [0×1 types.untyped.Set]
                                      general_optophysiology: [0×1 types.untyped.Set]
                                        general_pharmacology: ''
                                            general_protocol: ''
                                general_related_publications: [1×1 types.untyped.DataStub]
                                          general_session_id: 'session_1234'
                                              general_slices: ''
                                       general_source_script: ''
                             general_source_script_file_name: ''
                                            general_stimulus: ''
                                             general_subject: []
                                             general_surgery: ''
                                               general_virus: ''
                                    general_was_generated_by: [1×1 types.untyped.DataStub]
                                                   intervals: [0×1 types.untyped.Set]
                                            intervals_epochs: []
                                     intervals_invalid_times: []
                                            intervals_trials: []
                                                  processing: [1×1 types.untyped.Set]
                                                     scratch: [0×1 types.untyped.Set]
                                       stimulus_presentation: [0×1 types.untyped.Set]
                                          stimulus_templates: [0×1 types.untyped.Set]
                                                       units: [1×1 types.core.Units]
    >>

This object contains properties that represent the contents of the NWB file, including metadata about the experiment and data containers for raw and processed data. The object is hierarchical, meaning you can access nested data using dot notation.

For an overview of the NWB file structure, see the `NWB File Structure <https://nwb-overview.readthedocs.io/en/latest/intro_to_nwb/2_file_structure.html>`_ section of the central 
`NWB Documentation <https://nwb-overview.readthedocs.io/en/latest/index.html>`_, or for technical details, refer to the `NWB Format Specification <https://nwb-schema.readthedocs.io/en/latest/format_description.html>`_.

One key difference between the :class:`NwbFile` object and the formal NWB structure is that some top-level groups, like ``general``, ``intervals`` and ``stimulus`` are flattened into top level properties of the :class:`NwbFile` object. This is only a convenience for easier access, and does not change the underlying structure of the NWB file.

Basic Navigation
----------------

We can explore an :class:`NwbFile` object just like any MATLAB structure. For example, to see the session description:

.. code-block:: MATLAB

    disp(nwb.session_description);

.. code-block:: text

    mouse in open exploration
    >> 

Display the raw data of the file:

.. code-block:: MATLAB

    >> disp(nwb.acquisition);

.. code-block:: text

    2×1 Set array with properties:

        ElectricalSeries: [types.core.ElectricalSeries]
        SpikeEvents_Shank0: [types.core.SpikeEventSeries]
    >> 

The acquistion property contains a :class:`types.untyped.Set` object, which is a dynamic collection of NWB objects. In this case, it contains two datasets: ``ElectricalSeries`` and ``SpikeEvents_Shank0``. 

To access a specific dataset, we can use the :meth:`Set.get` method:

.. code-block:: MATLAB

    >> disp(nwb.acquisition.get('ElectricalSeries'));

.. code-block:: text

      ElectricalSeries with properties:
    
        channel_conversion_axis: 1
                     electrodes: [1×1 types.hdmf_common.DynamicTableRegion]
             channel_conversion: []
                      filtering: ''
             starting_time_unit: 'seconds'
            timestamps_interval: 1
                timestamps_unit: 'seconds'
                           data: [1×1 types.untyped.DataStub]
                      data_unit: 'volts'
                       comments: 'no comments'
                        control: []
            control_description: ''
                data_continuity: ''
                data_conversion: 1
                    data_offset: 0
                data_resolution: -1
                    description: 'no description'
                  starting_time: 0
             starting_time_rate: 30000
                     timestamps: []
    >> 


Data Types in NWB Files
-----------------------

There are 3 primary data types you will encounter when working with NWB files:

- MATLAB fundamental classes (e.g., ``char``, ``numeric``, ``cell``)
- NWB schema-defined types (e.g., :class:`types.core.TimeSeries`, :class:`types.core.ElectricalSeries`, :class:`types.hdmf_common.DynamicTable`)
- :ref:`Utility types<matnwb-read-untyped-intro>` (e.g., ``types.untyped.Set``, ``types.untyped.DataStub``)

TODO: Briefly discuss schema and utility types.

.. _matnwb-read-nwbfile-searchfor:

Finding Data: The searchFor Method
----------------------------------

When working with complex NWB files, manually exploring every property can be time-consuming. The :meth:`NwbFile.searchFor` method lets you search for specific types of data across the entire file:

.. code-block:: MATLAB

    electricalseries_map = nwb.searchFor('ElectricalSeries')

.. code-block:: output

    electricalseries_map = 
    
      Map with properties:
    
            Count: 3
          KeyType: char
        ValueType: any
    >> 

The ``searchFor`` method returns a MATLAB ``containers.Map`` object where:

- **Keys** are the paths (within the file) to each found object
- **Values** are the actual data objects

.. code-block:: MATLAB

    % See what was found
    paths = electricalseries_map.keys();      % Cell array of paths
    objects = electricalseries_map.values();  % Cell array of objects
    
    % Display the paths
    for i = 1:length(paths)
        fprintf('Found %s at: %s\n', class(objects{i}), paths{i});
    end

.. code-block:: text

    Found types.core.ElectricalSeries at: /acquisition/ElectricalSeries
    Found types.core.ElectricalSeries at: /processing/ecephys/nwbdatainterface/FilteredEphys/electricalseries/FilteredElectricalSeries
    Found types.core.ElectricalSeries at: /processing/ecephys/nwbdatainterface/LFP/electricalseries/ElectricalSeries
    >>

**Including Subclasses:**

Some searches benefit from including related data types. Use the ``'includeSubClasses'`` option:

.. code-block:: MATLAB

    % Find all types of time series (including specialized ones)
    all_timeseries = nwb.searchFor('TimeSeries', 'includeSubClasses');
    disp(all_timeseries.values')

.. code-block:: text
    
    {1×1 types.core.ElectricalSeries   }
    {1×1 types.core.SpikeEventSeries   }
    {1×1 types.core.ElectricalSeries   }
    {1×1 types.core.ElectricalSeries   }
    {1×1 types.core.DecompositionSeries}

    >>


This is useful because many NWB data types are specialized versions of more general types.

Retrieving Found Objects: The resolve Method
---------------------------------------------

Once you've found data using ``searchFor``, you can retrieve specific objects either directly from the values of the ``containers.Map`` object or using their paths with the :meth:`NwbFile.resolve` method:

.. code-block:: MATLAB

    all_electricalseries_paths = electricalseries_map.keys();      % Cell array of paths
    first_path = all_electricalseries_paths{1};
        
    % Retrieve the object using its path
    electricalseries_obj = nwb.resolve(first_path);

The ``resolve`` method is particularly useful when you:

- Want to access objects found through ``searchFor``
- Have a specific path and want to retrieve the object

Working with the Data
---------------------

Once you have a data object (whether found through navigation, search, or resolve), you can access its contents:

.. code-block:: MATLAB

    % Most data objects have a .data property
    raw_data = electricalseries_obj.data.load();
    size(raw_data)
    
    % Check for additional metadata
    fprintf('Description: %s\n', electricalseries_obj.description);

.. code-block:: text

    ans =

            12        3000

    Description: no description
    >>

Remember that data is not loaded into memory until you call ``.load()``. This allows you to work with very large files without overwhelming system memory. See the section on :ref:`matnwb-read-untyped-datastub-datapipe` for more information.

The Connection to HDF5
-----------------------

Under the hood, NWB files are stored in HDF5 format, which is why you see path-like structures (e.g., ``/acquisition/ElectricalSeries``). However, the NwbFile object abstracts away most of the HDF5 complexity, allowing you to work with the data using familiar MATLAB syntax.
