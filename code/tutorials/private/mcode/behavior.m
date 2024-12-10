%% Behavior Data
% This tutorial will guide you in writing behavioral data to NWB.
%% Creating an NWB File
% Create an NWBFile object with the required fields (|session_description|, 
% |identifier|, and |session_start_time|) and additional metadata.

nwb = NwbFile( ...
    'session_description', 'mouse in open exploration',...
    'identifier', 'Mouse5_Day3', ...
    'session_start_time', datetime(2018, 4, 25, 2, 30, 3, 'TimeZone', 'local'), ...
    'general_experimenter', 'My Name', ... % optional
    'general_session_id', 'session_1234', ... % optional
    'general_institution', 'University of My Institution', ... % optional
    'general_related_publications', 'DOI:10.1016/j.neuron.2016.12.011'); % optional
nwb
%% SpatialSeries: Storing continuous spatial data
% <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpatialSeries.html 
% |SpatialSeries|> is a subclass of <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeSeries.html 
% |TimeSeries|> that represents data in space, such as the spatial direction e.g., 
% of gaze or travel or position of an animal over time.
% 
% Create data that corresponds to x, y position over time.

position_data = [linspace(0, 10, 50); linspace(0, 8, 50)]; % 2 x nT array
%% 
% In <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpatialSeries.html 
% |SpatialSeries|> data, the first dimension is always time (in seconds), the 
% second dimension represents the x, y position. However, as described in the 
% <https://neurodatawithoutborders.github.io/matnwb/tutorials/html/dimensionMapNoDataPipes.html 
% dimensionMapNoDataPipes> tutorial, when a MATLAB array is exported to HDF5, 
% the array is transposed. Therefore, in order to correctly export the data, in 
% MATLAB the last dimension of an array should be time. <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpatialSeries.html 
% |SpatialSeries|> data should be stored as one continuous stream as it is acquired, 
% not by trials as is often reshaped for analysis. Data can be trial-aligned on-the-fly 
% using the trials table. See the trials tutorial for further information.
% 
% For position data |reference_frame| indicates the zero-position, e.g. the 
% 0,0 point might be the bottom-left corner of an enclosure, as viewed from the 
% tracking camera.

timestamps = linspace(0, 50, 50)/ 200;
position_spatial_series = types.core.SpatialSeries( ...
    'description', 'Postion (x, y) in an open field.', ...
    'data', position_data, ...
    'timestamps', timestamps, ...
    'reference_frame', '(0,0) is the bottom left corner.' ...
)
%% Position: Storing position measured over time
% To help data analysis and visualization tools know that this <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpatialSeries.html 
% |SpatialSeries|> object represents the position of the subject, store the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpatialSeries.html 
% |SpatialSeries|> object inside a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Position.html 
% |Position|> object, which can hold one or more <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpatialSeries.html 
% |SpatialSeries|> objects.

position = types.core.Position();
position.spatialseries.set('SpatialSeries', position_spatial_series);
%% Create a Behavior Processing Module
% Create a processing module called "behavior" for storing behavioral data in 
% the NWBFile, then add the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Position.html 
% |Position|> object to the processing module.

behavior_processing_module = types.core.ProcessingModule('description', 'stores behavioral data.');
behavior_processing_module.nwbdatainterface.set("Position", position);
nwb.processing.set("behavior", behavior_processing_module);
%% CompassDirection: Storing view angle measured over time
% Analogous to how position can be stored, we can create a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpatialSeries.html 
% |SpatialSeries|> object for representing the view angle of the subject.
% 
% For direction data |reference_frame| indicates the zero direction, for instance 
% in this case "straight ahead" is 0 radians.

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
%% 
% We can add a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/CompassDirection.html 
% |CompassDirection|> object to the behavior processing module the same way we 
% have added the position data.

%behavior_processing_module = types.core.ProcessingModule("stores behavioral data.");  % if you have not already created it
behavior_processing_module.nwbdatainterface.set('CompassDirection', direction);
%nwb.processing.set('behavior', behavior_processing_module); % if you have not already added it
%% BehaviorTimeSeries: Storing continuous behavior data
% <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/BehavioralTimeSeries.html 
% |BehavioralTimeSeries|> is an interface for storing continuous behavior data, 
% such as the speed of a subject.

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

%behavior_processing_module = types.core.ProcessingModule("stores behavioral data.");  % if you have not already created it
behavior_processing_module.nwbdatainterface.set('BehavioralTimeSeries', behavioral_time_series);
%nwb.processing.set('behavior', behavior_processing_module); % if you have not already added it
%% BehavioralEvents: Storing behavioral events
% <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/BehavioralEvents.html 
% |BehavioralEvents|> is an interface for storing behavioral events. We can use 
% it for storing the timing and amount of rewards (e.g. water amount) or lever 
% press times.

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

%behavior_processing_module = types.core.ProcessingModule("stores behavioral data.");  % if you have not already created it
behavior_processing_module.nwbdatainterface.set('BehavioralEvents', behavioral_events);
%nwb.processing.set('behavior', behavior_processing_module); % if you have not already added it
%% 
% Storing only the timestamps of the events is possible with the ndx-events 
% NWB extension. You can also add labels associated with the events with this 
% extension. You can find information about installation and example usage <https://github.com/nwb-extensions/ndx-events-record 
% here>.
%% BehavioralEpochs: Storing intervals of behavior data
% <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/BehavioralEpochs.html 
% |BehavioralEpochs|> is for storing intervals of behavior data. <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/BehavioralEpochs.html 
% |BehavioralEpochs|> uses <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/IntervalSeries.html 
% |IntervalSeries|> to represent the time intervals. Create an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/IntervalSeries.html 
% |IntervalSeries|> object that represents the time intervals when the animal 
% was running. IntervalSeries uses 1 to indicate the beginning of an interval 
% and -1 to indicate the end.

run_intervals = types.core.IntervalSeries( ...
    'description', 'Intervals when the animal was running.', ...
    'data', [1, -1, 1, -1, 1, -1], ...
    'timestamps', [0.5, 1.5, 3.5, 4.0, 7.0, 7.3] ...
);

behavioral_epochs = types.core.BehavioralEpochs();
behavioral_epochs.intervalseries.set('running', run_intervals);
%% 
% You can add more than one <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/IntervalSeries.html 
% |IntervalSeries|> to a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/BehavioralEpochs.html 
% |BehavioralEpochs|> object.

sleep_intervals = types.core.IntervalSeries( ...
    'description', 'Intervals when the animal was sleeping', ...
    'data', [1, -1, 1, -1], ...
    'timestamps', [15.0, 30.0, 60.0, 95.0] ...
);
behavioral_epochs.intervalseries.set('sleeping', sleep_intervals);

% behavior_processing_module = types.core.ProcessingModule("stores behavioral data.");
% behavior_processing_module.nwbdatainterface.set('BehavioralEvents', behavioral_events);
% nwb.processing.set('behavior', behavior_processing_module);
% Another approach: TimeIntervals
% Using <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeIntervals.html 
% |TimeIntervals|> to represent time intervals is often preferred over <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/BehavioralEpochs.html 
% |BehavioralEpochs|> and <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/IntervalSeries.html 
% |IntervalSeries|>. <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeIntervals.html 
% |TimeIntervals|> is a subclass of <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+hdmf_common/DynamicTable.html 
% |DynamicTable|>, which offers flexibility for tabular data by allowing the addition 
% of optional columns which are not defined in the standard DynamicTable class.

sleep_intervals = types.core.TimeIntervals( ...
    'description', 'Intervals when the animal was sleeping.', ...
    'colnames', {'start_time', 'stop_time', 'stage'} ...
);

sleep_intervals.addRow('start_time', 0.3, 'stop_time', 0.35, 'stage', 1);
sleep_intervals.addRow('start_time', 0.7, 'stop_time', 0.9, 'stage', 2);
sleep_intervals.addRow('start_time', 1.3, 'stop_time', 3.0, 'stage', 3);

nwb.intervals.set('sleep_intervals', sleep_intervals);
%% EyeTracking: Storing continuous eye-tracking data of gaze direction
% <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/EyeTracking.html 
% |EyeTracking|> is for storing eye-tracking data which represents direction of 
% gaze as measured by an eye tracking algorithm. An <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/EyeTracking.html 
% |EyeTracking|> object holds one or more <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpatialSeries.html 
% |SpatialSeries|> objects that represent the gaze direction over time extracted 
% from a video.

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

% behavior_processing_module = types.core.ProcessingModule("stores behavioral data.");
behavior_processing_module.nwbdatainterface.set('EyeTracking', eye_tracking);
% nwb.processing.set('behavior', behavior_processing_module);
%% PupilTracking: Storing continuous eye-tracking data of pupil size
% <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/PupilTracking.html 
% |PupilTracking|> is for storing eye-tracking data which represents pupil size. 
% <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/PupilTracking.html 
% |PupilTracking|> holds one or more <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeSeries.html 
% |TimeSeries|> objects that can represent different features such as the dilation 
% of the pupil measured over time by a pupil tracking algorithm.

pupil_diameter = types.core.TimeSeries( ...
    'description', 'Pupil diameter extracted from the video of the right eye.', ...
    'data', linspace(0.001, 0.002, 50), ...
    'starting_time', 1.0, ... % NB: Important to set starting_time when using starting_time_rate
    'starting_time_rate', 20.0, ... % Hz
    'data_unit', 'meters' ...
);

pupil_tracking = types.core.PupilTracking();
pupil_tracking.timeseries.set('pupil_diameter', pupil_diameter);

% behavior_processing_module = types.core.ProcessingModule("stores behavioral data.");
behavior_processing_module.nwbdatainterface.set('PupilTracking', pupil_tracking);
% nwb.processing.set('behavior', behavior_processing_module);
%% Writing the behavior data to an NWB file
% All of the above commands build an NWBFile object in-memory. To write this 
% file, use <https://neurodatawithoutborders.github.io/matnwb/doc/nwbExport.html 
% |nwbExport|>|.|

% Save to tutorials/tutorial_nwb_files folder
nwbFilePath = misc.getTutorialNwbFilePath('behavior_tutorial.nwb');
nwbExport(nwb, nwbFilePath);
fprintf('Exported NWB file to "%s"\n', 'behavior_tutorial.nwb')