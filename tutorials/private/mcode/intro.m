%% Introduction to MatNWB
% *Goal:* In this tutorial we will create and save an NWB file that holds metadata 
% and data from a fictional session in which a mouse searches for cookie crumbs 
% in an open arena. At the end we will read the file back for a quick inspection.
% 
% *Prerequisites*: MATLAB R2019b or later with <https://matnwb--749.org.readthedocs.build/en/749/pages/getting_started/installation_users.html 
% MatNWB installed>
%% 
%% Set up the NWB File
% An NWB file must have a unique |*identifier*|, a |*session_description*|, 
% and a |*session_start_time*|. Let’s start by creating a new <https://matnwb.readthedocs.io/en/latest/pages/functions/NwbFile.html 
% |*NwbFile*|> object and assigning values to those required fields as well as 
% some recommended metadata fields:

nwb = NwbFile( ...
    'identifier', 'MyLab_20250411_1530_AL', ... % Unique ID
    'session_description', 'Mouse searching for cookie crumbs in an open arena', ...
    'session_start_time', datetime(2025,4,11,15,30,0, 'TimeZone', 'local'), ...
    'general_experimenter', 'Doe, Jane', ... % optional
    'general_session_id', 'session_001', ... % optional
    'general_institution', 'Dept. of Neurobiology, Cookie Institute', ... % optional
    'general_related_publications', {'DOI:10.1016/j.neuron.2016.12.011'}); % optional

% Display the nwb object
nwb
%% 
% Great! You now have an in-memory <https://matnwb.readthedocs.io/en/latest/pages/functions/NwbFile.html 
% |*NwbFile*|> object with all the required metadata. In the following sections, 
% we will populate the file with additional metadata and data from our fictional 
% session.
% 
% *Tip: See the* <https://nwbinspector.readthedocs.io/en/dev/best_practices/nwbfile_metadata.html#file-metadata 
% *NWBFile Best Practices*> *for detailed recommendations of which metadata to 
% add to the* <https://matnwb.readthedocs.io/en/latest/pages/functions/NwbFile.html 
% |*NwbFile*|>
%% Add Subject Metadata
% First we will describe the mouse that took part in this session using the 
% <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Subject.html 
% |*Subject*|> class.
% 
% 
% 
% All of these fields accept free-form text, so any value is technically valid, 
% but we will follow the <https://nwbinspector.readthedocs.io/en/dev/best_practices/nwbfile_metadata.html#subject 
% *Best Practices*> recommendations:
%% 
% * *age* – use an <https://en.wikipedia.org/wiki/ISO_8601#Durations *ISO 8601 
% Duration format*>, e.g. |P90D| for post-natal day 90
% * *species* – give the *Latin binomial*, e.g. |Mus musculus|, |Homo sapiens|
% * *sex* – use a single letter: *F* (female), *M* (male), *U* (unknown), or 
% *O* (other)

subject = types.core.Subject( ...
    'subject_id', 'MQ01', ...        % Unique animal ID
    'description', 'Meet Monty Q., our cookie-loving mouse.', ...
    'age', 'P90D', ...              % ISO-8601 duration (post-natal day 90)
    'species', 'Mus musculus', ...  % Latin binomial
    'sex', 'M' ...                  % F | M | U | O
);

nwb.general_subject = subject;      % Subject goes into the `general_subject` property
disp(nwb.general_subject)           % Confirm the subject is now part of the file
%% Add TimeSeries Data
% Many experiments generate signals sampled over time and in NWB you store those 
% signals in a <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeSeries.html 
% |*TimeSeries*|> object. The diagram below highlights the key fields of the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeSeries.html 
% |*TimeSeries*|> class.
% 
% 
% Regularly Sampled Data
% While our mouse hunted cookie crumbs, an *indoor-positioning sensor* (IPS) 
% streamed X/Y coordinates at 10 Hz for 30 s. We’ll store the resulting 2 × N 
% matrix in a <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeSeries.html 
% |*TimeSeries*|> object.

% Synthetic 2-D trajectory  (helper returns a 2×300 array)
data = getRandomTrajectory();

time_series_with_rate = types.core.TimeSeries( ...
    'description', ['2D position of mouse in arena. The first column ', ...
        'represents x coordinates, the second column represents y coordinates'], ... % Optional
    'data', data, ...                               % Required
    'data_unit', 'meters', ...                      % Required
    'starting_time', 0.0, ...                       % Required
    'starting_time_rate', 10.0);                    % Required
disp(time_series_with_rate)
%% 
% Next, we add the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeSeries.html 
% |*TimeSeries*|> to the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/NWBFile.html 
% |*NWBFile*|> by inserting it into the file’s |*acquisition*| container. This 
% container can hold any number of data objects—each stored as a name-value pair 
% where the _name_ is a user-defined name and the _value_ is the data object itself:

nwb.acquisition.set('IPSTimeseries', time_series_with_rate);
% Confirm that the timeseries was added to the file
disp( size( nwb.acquisition.get('IPSTimeseries').data ) ) % Should show 2, 300
% Irregularly Sampled Data
% To save irregularly sampled data, we should replace the single |*starting_time* 
% + *rate*| pair with an explicit vector of |*timestamps*|. Let's pretend that 
% the IPS drops samples and has an irregular sampling rate:

[irregularData, timepoints] = getIrregularRandomTrajectory();
% Drop frame 120 to create a gap
irregularData(:,120) = []; timepoints(120) = [];

time_series_with_timestamps = types.core.TimeSeries( ...
    'description', 'XY position (irregular)', ...
    'data', irregularData, ...
    'data_unit', 'meters', ...
    'timestamps', timepoints);

% Add the TimeSeries to the NWB file
nwb.acquisition.set('IPSTimeseriesWithJitterAndMissingSamples', time_series_with_timestamps);

% Quick sanity check: are the first three Δt uneven?
disp(diff(time_series_with_timestamps.timestamps(1:4)))       % should NOT all be 0.1 s
%% 
% *Key difference:* |*timestamps*| takes the place of |*starting_time*| and 
% |*starting_time_rate*.| Everything else—adding the series to |*acquisition*|, 
% slicing, plotting—works exactly the same. 
% 
% With both a *rate-based* and an *irregular* |TimeSeries| in your file, you’ve 
% now covered the two most common clocking scenarios you’ll meet in real experiments.
%% Other Types of Time Series 
% The <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeSeries.html 
% |*TimeSeries*|> class has a family of specialized subclasses—each adding or 
% tweaking fields to suit a particular kind of data. One example is the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/AnnotationSeries.html 
% |*AnnotationSeries*|> → plain-text labels tied to timestamps (cues, notes, rewards, 
% etc.).
% 
% *Tip*: For a full overview of <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeSeries.html 
% |*TimeSeries*|> subtypes, please check out the <https://nwb-schema.readthedocs.io/en/latest/format.html#type-hierarchy 
% type hierarchy> in the NWB schema documentation.
% 
% A crumb dispenser _dings_ at random times and drops different types of cookie 
% crumbs. We’ll record the drop events in an <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/AnnotationSeries.html 
% |*AnnotationSeries*|> and store it under |*stimulus_presentation*|.

% Create an AnnotationSeries object with annotations for airpuff stimuli
annotations = types.core.AnnotationSeries( ...
    'description', 'Log time and flavour for cookie crumb drops', ...
    'data', {'Snickerdoodles', 'Chocolate Chip Cookies', 'Peanut Butter Cookies'}, ...
    'timestamps', [3.0, 12.0, 25.0] ...
);

% Add the AnnotationSeries to the NWBFile's stimulus group
nwb.stimulus_presentation.set('FoodDrops', annotations);
%% 
% *What to remember*
%% 
% * |AnnotationSeries| is still a |TimeSeries|, but |data| is *text*, not numbers.
% * Put cue / reward / comment streams in |*stimulus_presentation*| (or another 
% container that fits your experiment).
%% 
% That’s it! You now have both continuous data (position) *and* discrete event 
% markers logged in your NWB file. In the next section we’ll look at storing processed 
% behavioral data such as the mouse’s X/Y path in arena coordinates.
%% Add Behavioral Data
% So far we’ve stored *raw, acquired* data—the IPS sensor’s 10 Hz position stream. 
% Now suppose a lab-mate is testing her new video-based deep-learning tracker 
% and hands you a _processed_ XY path.
% SpatialSeries and Position
% To store the processed XY path, we can use another subclass of the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeSeries.html 
% |*TimeSeries*|>: the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/SpatialSeries.html 
% |*SpatialSeries*|>. This class adds a |*reference_frame*| property that defines 
% what the data coordinates are measured relative to. We will create the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/SpatialSeries.html 
% |*SpatialSeries*|> and add it to a <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Position.html 
% |*Position*|> object as a way to inform data analysis and visualization tools 
% that this <https://pynwb.readthedocs.io/en/latest/pynwb.behavior.html#pynwb.behavior.SpatialSeries 
% |*SpatialSeries*|> object represents the position of the subject. 
% 
% The relationship of the three classes just mentioned is shown in the UML diagram 
% below. For our purposes, all you need to know is that an open triangle means 
% "extends" (i.e., is a specialized subtype of), and an open diamond means "is 
% contained within" (Learn more about class diagrams on <https://en.wikipedia.org/wiki/Class_diagram 
% the wikipedia page>).
% 
% 
% 
% 

positionData = getVideoTrackerData();

% Create SpatialSeries object
spatial_series_ts = types.core.SpatialSeries( ...
    'data', positionData, ...
    'reference_frame', '(0,0) is bottom left corner of arena', ...
    'starting_time', 0, ...
    'starting_time_rate', 30 ...
);

% Create Position object and add SpatialSeries
position = types.core.Position('SpatialSeries', spatial_series_ts);
%% 
% In NWB, results produced *after* the experiment belong in a *processing module*, 
% separate from the immutable acquisition data. The difference is that the processed 
% data could change later if the video-tracking software was improved, whereas 
% the raw data is streamed directly from a sensor, and should never change. Because 
% processed data can be very diverse, NWB allows us to create processing modules, 
% which are like folders, to store related processed data or data that comes from 
% a single algorithm. 
% 
% Create a processing module called "behavior" for storing behavioral data in 
% the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/NWBFile.html 
% |*NWBFile*|> and add the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Position.html 
% |*Position*|> object to the module.

% Create processing module
behavior_module = types.core.ProcessingModule(...
    'description', 'Contains behavioral data');

% Add the Position object (that holds the SpatialSeries object) to the module 
% and name the Position object MousePosition
behavior_module.nwbdatainterface.set('MousePosition', position);

% Finally, add the processing module to the NWBFile object, and name the 
% processing module "behavior"
nwb.processing.set('behavior', behavior_module);
% Trials
% Our experiment follows a trial structure where each trials lasts for 10 seconds, 
% and we are recording how long it takes the mouse to find the cookie crumb. Trials 
% are stored using the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeIntervals.html 
% |*TimeIntervals*|> type, a subclass of the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html 
% |*DynamicTable*|> type. <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html 
% |*DynamicTable*|> objects are used to store tabular metadata throughout NWB, 
% and is often used for storing information about trials, electrodes, and sorted 
% units. They offer flexibility for tabular data by allowing required columns, 
% optional columns, and custom columns. The <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeIntervals.html 
% |*TimeIntervals*|> trials table can be thought of as a table with this structure:
% 
% 
% 
% Here, we are adding two custom columns:
%% 
% * |*time_to_find*| (float) - which will be the time it took out mouse to find 
% the treats after the cookie ding was played.
% * *was_found* (boolean) - whether cookie crumb was found on time.

trials = types.core.TimeIntervals( ...
    'colnames', {'start_time', 'stop_time', 'time_to_find', 'was_found'}, ...
    'description', 'trial data and properties');

trials.addRow('start_time', 0, 'stop_time', 10, 'time_to_find', 3.2, 'was_found', true)
trials.addRow('start_time', 10.0, 'stop_time', 20.0, 'time_to_find', 4.7, 'was_found', false)
trials.addRow('start_time', 20.0, 'stop_time', 30.0, 'time_to_find', 3.9, 'was_found', true)

trials.toTable() % visualize the table
%% 
% When adding trials to the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/NWBFile.html 
% |*NWBFile*|> object, there are two ways to do it:

% Alternative A - There is only one trials table:
nwb.intervals_trials = trials;

% Alternative B - There are multiple trials tables, you will need to use custom names for
% each one:
nwb.intervals.set('CookieSearchTrials', trials);
%% 
% For a more detailed tutorial on dynamic tables, see the <./dynamic_tables.mlx 
% Dynamic tables> tutorial.
%% Write
% Now, to write the NWB file that we have built so far:

nwbExport(nwb, 'intro_tutorial.nwb')
%% 
% We can use the <https://www.hdfgroup.org/downloads/hdfview/ HDFView> application 
% to inspect the resulting NWB file.
% 
% 
%% Read
% We can also read the file back using MatNWB and inspect its contents. 

read_nwbfile = nwbRead('intro_tutorial.nwb', 'ignorecache')
%% 
% We can print the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/SpatialSeries.html 
% |*SpatialSeries*|> data traversing the hierarchy of objects. The processing 
% module called |'behavior'| contains our <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Position.html 
% |*Position*|> object named |'MousePosition'|. The <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Position.html 
% |*Position*|> object contains our <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/SpatialSeries.html 
% |*SpatialSeries*|> object named |'SpatialSeries'|.

read_spatial_series = read_nwbfile.processing.get('behavior'). ...
    nwbdatainterface.get('MousePosition').spatialseries.get('SpatialSeries')
% Loading Data
% Counter to normal MATLAB workflow, data arrays are read passively from the 
% file. Calling |*read_spatial_series.data*| does not read the data values, but 
% presents a |*DataStub*| object that can be indexed to read data. 

read_spatial_series.data
%% 
% This allows you to conveniently work with datasets that are too large to fit 
% in RAM all at once. Access all the data in the matrix using the |*load*| method 
% with no arguments. 

read_spatial_series.data.load()
%% 
% If you only need a section of the data, you can read only that section by 
% indexing the |*DataStub*| object like a normal array in MATLAB. This will just 
% read the selected region from disk into RAM. This technique is particularly 
% useful if you are dealing with a large dataset that is too big to fit entirely 
% into your available RAM.

read_spatial_series.data(:, 1:10)
%% Next Steps
% This concludes the introductory tutorial. Please proceed to one of the specialized 
% tutorials, which are designed to succeed this one.
%% 
% * <./ecephys.mlx Extracellular electrophysiology>
% * <./icephys.mlx Intracellular electrophysiology>
% * <./ophys.mlx Optical physiology>
%% 
% Refer to the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/index.html 
% API documentation> to learn what data types are available.
% 
% 
%% Local Functions

function result = getRandomTrajectory()
    samplingRate        = 10;                       % 10 Hz sampling
    experimentDuration  = 30; 
    t = 0 : 1/samplingRate : experimentDuration;    % continuous timeline
    t = t(1:300);

    % random walk in metres
    rng(42);
    step      = 0.02 * randn(2, numel(t));
    result    = cumsum(step,2);

    rng('default')
end

function [data, timepoints] = getIrregularRandomTrajectory()
    data = getRandomTrajectory();
    samplingRate = 10;                                          % 10 Hz sampling    
    jitter = 0.02 * randn(1, size(data, 2));                    % ±20 ms
    timepoints = (0:size(data, 2) - 1) / samplingRate + jitter; % Irregular sampling
end

function result = getVideoTrackerData()
    % Get some 2D trajectory
    data = getRandomTrajectory();

    % Number of original points
    n = length(data);

    % Define original and new sample positions
    xOriginal = 1:n;
    xNew = linspace(1, n, n*3);

    % Preallocate result
    result = zeros(2, numel(xNew));

    % Interpolate each row separately
    result(1,:) = interp1(xOriginal, data(1,:), xNew, 'linear');
    result(2,:) = interp1(xOriginal, data(2,:), xNew, 'linear');
end