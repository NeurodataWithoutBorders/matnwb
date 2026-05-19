.. _behavior-tutorial:

Behavior Data
=============

.. image:: https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg
   :target: https://matlab.mathworks.com/open/github/v1?repo=NeurodataWithoutBorders/matnwb&file=tutorials/behavior.mlx
   :alt: Open in MATLAB Online
.. image:: https://img.shields.io/badge/View-Rendered_Live_Script-blue
   :target: ../../_static/html/tutorials/behavior.html
   :alt: View rendered Live Script


.. contents:: On this page
   :local:
   :depth: 2

This tutorial will guide you in writing behavioral data to NWB.

Creating an NWB File
--------------------

Create an NWBFile object with the required fields (``session_description``, ``identifier``, and ``session_start_time``) and additional metadata.

.. code-block:: matlab

   nwb = NwbFile( ...
       'session_description', 'mouse in open exploration',...
       'identifier', 'Mouse5_Day3', ...
       'session_start_time', datetime(2018, 4, 25, 2, 30, 3, 'TimeZone', 'local'), ...
       'general_experimenter', 'My Name', ... % optional
       'general_session_id', 'session_1234', ... % optional
       'general_institution', 'University of My Institution', ... % optional
       'general_related_publications', 'DOI:10.1016/j.neuron.2016.12.011'); % optional
   nwb

.. code-block:: text

   nwb = 
     NwbFile with properties:
   
                                                nwb_version: '2.9.0'
                                           file_create_date: []
                                                 identifier: 'Mouse5_Day3'
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
                                       general_experimenter: 'My Name'
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

SpatialSeries: Storing continuous spatial data
----------------------------------------------

`SpatialSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/SpatialSeries.html>`_ is a subclass of `TimeSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeSeries.html>`_ that represents data in space, such as the spatial direction e.g., of gaze or travel or position of an animal over time.

Create data that corresponds to x, y position over time.

.. code-block:: matlab

   position_data = [linspace(0, 10, 50); linspace(0, 8, 50)]; % 2 x nT array

In `SpatialSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/SpatialSeries.html>`_ data, the first dimension is always time (in seconds), the second dimension represents the x, y position. However, as described in the `dimensionMapNoDataPipes <dimensionMapNoDataPipes>`_ tutorial, when a MATLAB array is exported to HDF5, the array is transposed. Therefore, in order to correctly export the data, in MATLAB the last dimension of an array should be time. `SpatialSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/SpatialSeries.html>`_ data should be stored as one continuous stream as it is acquired, not by trials as is often reshaped for analysis. Data can be trial-aligned on-the-fly using the trials table. See the trials tutorial for further information.

For position data ``reference_frame`` indicates the zero-position, e.g. the 0,0 point might be the bottom-left corner of an enclosure, as viewed from the tracking camera.

.. code-block:: matlab

   timestamps = linspace(0, 50, 50)/ 200;
   position_spatial_series = types.core.SpatialSeries( ...
       'description', 'Postion (x, y) in an open field.', ...
       'data', position_data, ...
       'timestamps', timestamps, ...
       'reference_frame', '(0,0) is the bottom left corner.' ...
       )

.. code-block:: text

   position_spatial_series = 
     SpatialSeries with properties:
   
           reference_frame: '(0,0) is the bottom left corner.'
        starting_time_unit: 'seconds'
       timestamps_interval: 1
           timestamps_unit: 'seconds'
                      data: [2x50 double]
                 data_unit: 'meters'
                  comments: 'no comments'
                   control: []
       control_description: ''
           data_continuity: ''
           data_conversion: 1
               data_offset: 0
           data_resolution: -1
               description: 'Postion (x, y) in an open field.'
             starting_time: []
        starting_time_rate: []
                timestamps: [0 0.0051 0.0102 0.0153 0.0204 0.0255 0.0306 0.0357 0.0408 0.0459 0.0510 0.0561 0.0612 0.0663 0.0714 0.0765 0.0816 0.0867 0.0918 0.0969 0.1020 0.1071 0.1122 0.1173 0.1224 0.1276 0.1327 0.1378 0.1429 0.1480 0.1531 … ] (1x50 double)

Position: Storing position measured over time
---------------------------------------------

To help data analysis and visualization tools know that this `SpatialSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/SpatialSeries.html>`_ object represents the position of the subject, store the `SpatialSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/SpatialSeries.html>`_ object inside a `Position <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Position.html>`_ object, which can hold one or more `SpatialSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/SpatialSeries.html>`_ objects.

.. code-block:: matlab

   position = types.core.Position();
   position.spatialseries.set('SpatialSeries', position_spatial_series);

Create a Behavior Processing Module
-----------------------------------

Create a processing module called "behavior" for storing behavioral data in the NWBFile, then add the `Position <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Position.html>`_ object to the processing module.

.. code-block:: matlab

   behavior_processing_module = types.core.ProcessingModule('description', 'stores behavioral data.');
   behavior_processing_module.nwbdatainterface.set("Position", position);
   nwb.processing.set("behavior", behavior_processing_module);

CompassDirection: Storing view angle measured over time
-------------------------------------------------------

Analogous to how position can be stored, we can create a `SpatialSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/SpatialSeries.html>`_ object for representing the view angle of the subject.

For direction data ``reference_frame`` indicates the zero direction, for instance in this case "straight ahead" is 0 radians.

.. code-block:: matlab

   view_angle_data = linspace(0, 4, 50);
   direction_spatial_series = types.core.SpatialSeries( ...
       'description', 'View angle of the subject measured in radians.', ...
       'data', view_angle_data, ...
       'timestamps', timestamps, ...
       'reference_frame', 'straight ahead', ...
       'data_unit', 'radians' ...
       );
   direction = types.core.CompassDirection();
   direction.spatialseries.set('spatial_series', direction_spatial_series);

We can add a `CompassDirection <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/CompassDirection.html>`_ object to the behavior processing module the same way we have added the position data.

.. code-block:: matlab

   behavior_processing_module.nwbdatainterface.set('CompassDirection', direction);

BehaviorTimeSeries: Storing continuous behavior data
----------------------------------------------------

`BehavioralTimeSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/BehavioralTimeSeries.html>`_ is an interface for storing continuous behavior data, such as the speed of a subject.

.. code-block:: matlab

   speed_data = linspace(0, 0.4, 50);
   
   speed_time_series = types.core.TimeSeries( ...
       'data', speed_data, ...
       'starting_time', 1.0, ... % NB: Important to set starting_time when using starting_time_rate
       'starting_time_rate', 10.0, ... % Hz
       'description', 'he speed of the subject measured over time.', ...
       'data_unit', 'm/s' ...
       );
   
   behavioral_time_series = types.core.BehavioralTimeSeries();
   behavioral_time_series.timeseries.set('speed', speed_time_series);
   
   % Add behavioral_time_series to the processing module
   behavior_processing_module.nwbdatainterface.set('BehavioralTimeSeries', behavioral_time_series);

BehavioralEvents: Storing behavioral events
-------------------------------------------

`BehavioralEvents <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/BehavioralEvents.html>`_ is an interface for storing behavioral events. We can use it for storing the timing and amount of rewards (e.g. water amount) or lever press times.

.. code-block:: matlab

   reward_amount = [1.0, 1.5, 1.0, 1.5];
   event_timestamps = [1.0, 2.0, 5.0, 6.0];
   
   time_series = types.core.TimeSeries( ...
       'data', reward_amount, ...
       'timestamps', event_timestamps, ...
       'description', 'The water amount the subject received as a reward.', ...
       'data_unit', 'ml' ...
       );
   
   behavioral_events = types.core.BehavioralEvents();
   behavioral_events.timeseries.set('lever_presses', time_series);
   
   % Add behavioral_events to the processing module
   behavior_processing_module.nwbdatainterface.set('BehavioralEvents', behavioral_events);

Storing only the timestamps of the events is possible with the ndx-events NWB extension. You can also add labels associated with the events with this extension. You can find information about installation and example usage `here <https://github.com/nwb-extensions/ndx-events-record>`_.

BehavioralEpochs: Storing intervals of behavior data
----------------------------------------------------

`BehavioralEpochs <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/BehavioralEpochs.html>`_ is for storing intervals of behavior data. `BehavioralEpochs <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/BehavioralEpochs.html>`_ uses `IntervalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/IntervalSeries.html>`_ to represent the time intervals. Create an `IntervalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/IntervalSeries.html>`_ object that represents the time intervals when the animal was running. IntervalSeries uses 1 to indicate the beginning of an interval and -1 to indicate the end.

.. code-block:: matlab

   run_intervals = types.core.IntervalSeries( ...
       'description', 'Intervals when the animal was running.', ...
       'data', [1, -1, 1, -1, 1, -1], ...
       'timestamps', [0.5, 1.5, 3.5, 4.0, 7.0, 7.3] ...
       );
   
   behavioral_epochs = types.core.BehavioralEpochs();
   behavioral_epochs.intervalseries.set('running', run_intervals);

You can add more than one `IntervalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/IntervalSeries.html>`_ to a `BehavioralEpochs <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/BehavioralEpochs.html>`_ object.

.. code-block:: matlab

   sleep_intervals = types.core.IntervalSeries( ...
       'description', 'Intervals when the animal was sleeping', ...
       'data', [1, -1, 1, -1], ...
       'timestamps', [15.0, 30.0, 60.0, 95.0] ...
       );
   behavioral_epochs.intervalseries.set('sleeping', sleep_intervals);
   
   % Add behavioral_epochs to the processing module
   behavior_processing_module.nwbdatainterface.set('BehavioralEpochs', behavioral_epochs);

Another approach: TimeIntervals
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Using `TimeIntervals <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeIntervals.html>`_ to represent time intervals is often preferred over `BehavioralEpochs <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/BehavioralEpochs.html>`_ and `IntervalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/IntervalSeries.html>`_. `TimeIntervals <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeIntervals.html>`_ is a subclass of `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_, which offers flexibility for tabular data by allowing the addition of optional columns which are not defined in the standard DynamicTable class.

.. code-block:: matlab

   sleep_intervals = types.core.TimeIntervals( ...
       'description', 'Intervals when the animal was sleeping.', ...
       'colnames', {'start_time', 'stop_time', 'stage'} ...
       );
   
   sleep_intervals.addRow('start_time', 0.3, 'stop_time', 0.35, 'stage', 1);
   sleep_intervals.addRow('start_time', 0.7, 'stop_time', 0.9, 'stage', 2);
   sleep_intervals.addRow('start_time', 1.3, 'stop_time', 3.0, 'stage', 3);
   
   nwb.intervals.set('sleep_intervals', sleep_intervals);

EyeTracking: Storing continuous eye-tracking data of gaze direction
-------------------------------------------------------------------

`EyeTracking <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/EyeTracking.html>`_ is for storing eye-tracking data which represents direction of gaze as measured by an eye tracking algorithm. An `EyeTracking <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/EyeTracking.html>`_ object holds one or more `SpatialSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/SpatialSeries.html>`_ objects that represent the gaze direction over time extracted from a video.

.. code-block:: matlab

   eye_position_data = [linspace(-20, 30, 50); linspace(30, -20, 50)];
   
   right_eye_position = types.core.SpatialSeries( ...
       'description', 'The position of the right eye measured in degrees.', ...
       'data', eye_position_data, ...
       'starting_time', 1.0, ... % NB: Important to set starting_time when using starting_time_rate
       'starting_time_rate', 50.0, ... % Hz
       'reference_frame', '(0,0) is middle', ...
       'data_unit', 'degrees' ...
       );
   
   left_eye_position = types.core.SpatialSeries( ...
       'description', 'The position of the right eye measured in degrees.', ...
       'data', eye_position_data, ...
       'starting_time', 1.0, ... % NB: Important to set starting_time when using starting_time_rate
       'starting_time_rate', 50.0, ... % Hz
       'reference_frame', '(0,0) is middle', ...
       'data_unit', 'degrees' ...
       );
   
   eye_tracking = types.core.EyeTracking();
   eye_tracking.spatialseries.set('right_eye_position', right_eye_position);
   eye_tracking.spatialseries.set('left_eye_position', left_eye_position);
   
   behavior_processing_module.nwbdatainterface.set('EyeTracking', eye_tracking);

PupilTracking: Storing continuous eye-tracking data of pupil size
-----------------------------------------------------------------

`PupilTracking <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/PupilTracking.html>`_ is for storing eye-tracking data which represents pupil size. `PupilTracking <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/PupilTracking.html>`_ holds one or more `TimeSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeSeries.html>`_ objects that can represent different features such as the dilation of the pupil measured over time by a pupil tracking algorithm.

.. code-block:: matlab

   pupil_diameter = types.core.TimeSeries( ...
       'description', 'Pupil diameter extracted from the video of the right eye.', ...
       'data', linspace(0.001, 0.002, 50), ...
       'starting_time', 1.0, ... % NB: Important to set starting_time when using starting_time_rate
       'starting_time_rate', 20.0, ... % Hz
       'data_unit', 'meters' ...
       );
   
   pupil_tracking = types.core.PupilTracking();
   pupil_tracking.timeseries.set('pupil_diameter', pupil_diameter);
   
   behavior_processing_module.nwbdatainterface.set('PupilTracking', pupil_tracking);

Writing the behavior data to an NWB file
----------------------------------------

All of the above commands build an NWBFile object in-memory. To write this file, use `nwbExport <https://matnwb.readthedocs.io/en/latest/pages/functions/nwbExport.html>`_.

.. code-block:: matlab

   % Save to tutorials/tutorial_nwb_files folder
   nwbFilePath = misc.getTutorialNwbFilePath('behavior_tutorial.nwb');
   nwbExport(nwb, nwbFilePath);
   fprintf('Exported NWB file to "%s"\n', 'behavior_tutorial.nwb')

.. code-block:: text

   Exported NWB file to "behavior_tutorial.nwb"
