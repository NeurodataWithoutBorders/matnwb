.. _ogen-tutorial:

Optogenetics
============

.. image:: https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg
   :target: https://matlab.mathworks.com/open/github/v1?repo=NeurodataWithoutBorders/matnwb&file=tutorials/ogen.mlx
   :alt: Open in MATLAB Online
.. image:: https://img.shields.io/badge/View-Rendered_Live_Script-blue
   :target: ../../_static/html/tutorials/ogen.html
   :alt: View rendered Live Script


.. contents:: On this page
   :local:
   :depth: 2

This tutorial will demonstrate how to write optogenetics data.

Creating an NWBFile object
--------------------------

When creating a NWB file, the first step is to create the ``NWBFile`` object using `NwbFile <https://matnwb.readthedocs.io/en/latest/pages/functions/NwbFile.html>`_.

.. code-block:: matlab

   nwb = NwbFile( ...
       'identifier', 'matnwb_optogenetics_tutorial', ...
       'session_description', 'mouse in open exploration', ...
       'session_start_time', datetime(2018, 4, 25, 2, 30, 3, 'TimeZone', 'local'), ...
       'general_experimenter', 'Last, First M.', ... % optional
       'general_session_id', 'session_1234', ... % optional
       'general_institution', 'University of My Institution', ... % optional
       'general_related_publications', 'DOI:10.1016/j.neuron.2016.12.011'); % optional
   nwb

.. code-block:: text

   nwb = 
     NwbFile with properties:
   
                                                nwb_version: '2.9.0'
                                           file_create_date: []
                                                 identifier: 'matnwb_optogenetics_tutorial'
                                        session_description: 'mouse in open exploration'
                                         session_start_time: {[2018-04-25T02:30:03.000000+02:00]}
                                  timestamps_reference_time: []
                                                acquisition: [0x1 types.untyped.Set]
                                                   analysis: [0x1 types.untyped.Set]
                                                    general: [0x1 types.untyped.Set]
                                    general_data_collection: ''
                                            general_devices: [0x1 types.untyped.Set]
                                     general_devices_models: [0x1 types.untyped.Set]
                             general_experiment_description: ''
                                       general_experimenter: 'Last, First M.'
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
                               general_related_publications: 'DOI:10.1016/j.neuron.2016.12.011'
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

It is recommended to store information about the experimental subject in the file. Create a `Subject <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Subject.html>`_ object to store metadata about the subject, then assign it to ``nwb.general_subject``.

.. code-block:: matlab

   subject = types.core.Subject( ...
       'subject_id', '001', ...
       'age', 'P90D', ...
       'description', 'mouse 1', ...
       'species', 'Mus musculus', ...
       'sex', 'M' ...
   );
   nwb.general_subject = subject;

Adding optogenetic data
-----------------------

The  ``ogen`` module contains two data types that you will need to write optogenetics data, `OptogeneticStimulusSite <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/OptogeneticStimulusSite.html>`_, which contains metadata about the stimulus site, and `OptogeneticSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/OptogeneticSeries.html>`_, which contains the values of the time series.

First, you need to create a `Device <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Device.html>`_ object linked to the ``NWBFile``:

.. code-block:: matlab

   device = types.core.Device();
   nwb.general_devices.set('Device', device);

Now, you can create and add an `OptogeneticStimulusSite <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/OptogeneticStimulusSite.html>`_.

.. code-block:: matlab

   ogen_stim_site = types.core.OptogeneticStimulusSite( ...
       'device', types.untyped.SoftLink(device), ...
       'description', 'This is an example optogenetic site.', ...
       'excitation_lambda', 600.0, ...
       'location', 'VISrl');
   
   nwb.general_optogenetics.set('OptogeneticStimulusSite', ogen_stim_site);

With the `OptogeneticStimulusSite <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/OptogeneticStimulusSite.html>`_ added, you can now create and add a `OptogeneticSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/OptogeneticSeries.html>`_. Here, we will generate some random data and specify the timing using ``rate``. If you have samples at irregular intervals, you should use ``timestamps`` instead.

.. code-block:: matlab

   ogen_series = types.core.OptogeneticSeries( ...
       'data', randn(20, 1), ...
       'site', types.untyped.SoftLink(ogen_stim_site), ...
       'starting_time', 0.0, ...
       'starting_time_rate', 30.0);  % Hz
   nwb.stimulus_presentation.set('OptogeneticSeries', ogen_series);
   
   nwb

.. code-block:: text

   nwb = 
     NwbFile with properties:
   
                                                nwb_version: '2.9.0'
                                           file_create_date: []
                                                 identifier: 'matnwb_optogenetics_tutorial'
                                        session_description: 'mouse in open exploration'
                                         session_start_time: {[2018-04-25T02:30:03.000000+02:00]}
                                  timestamps_reference_time: []
                                                acquisition: [0x1 types.untyped.Set]
                                                   analysis: [0x1 types.untyped.Set]
                                                    general: [0x1 types.untyped.Set]
                                    general_data_collection: ''
                                            general_devices: [1x1 types.untyped.Set]
                                     general_devices_models: [0x1 types.untyped.Set]
                             general_experiment_description: ''
                                       general_experimenter: 'Last, First M.'
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
                                       general_optogenetics: [1x1 types.untyped.Set]
                                     general_optophysiology: [0x1 types.untyped.Set]
                                       general_pharmacology: ''
                                           general_protocol: ''
                               general_related_publications: 'DOI:10.1016/j.neuron.2016.12.011'
                                         general_session_id: 'session_1234'
                                             general_slices: ''
                                      general_source_script: ''
                            general_source_script_file_name: ''
                                           general_stimulus: ''
                                            general_subject: [1x1 types.core.Subject]
                                            general_surgery: ''
                                              general_virus: ''
                                   general_was_generated_by: ''
                                                  intervals: [0x1 types.untyped.Set]
                                           intervals_epochs: []
                                    intervals_invalid_times: []
                                           intervals_trials: []
                                                 processing: [0x1 types.untyped.Set]
                                                    scratch: [0x1 types.untyped.Set]
                                      stimulus_presentation: [1x1 types.untyped.Set]
                                         stimulus_templates: [0x1 types.untyped.Set]
                                                      units: []

Now you can write the NWB file.

.. code-block:: matlab

   nwbExport(nwb, 'ogen_tutorial.nwb');
