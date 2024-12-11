%% Introduction to MatNWB
%% Installing MatNWB
% Use the code below within the brackets to install MatNWB from source. MatNWB 
% works by automatically creating API classes based on the schema.

%{
!git clone https://github.com/NeurodataWithoutBorders/matnwb.git
addpath(genpath(pwd));
%}
%% Set up the NWB File
% An NWB file represents a single session of an experiment. Each file must have 
% a session_description, identifier, and session start time. Create a new <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/NWBFile.html 
% |*NWBFile*|> object with those and additional metadata using the <https://neurodatawithoutborders.github.io/matnwb/doc/NwbFile.html 
% |*NwbFile*|> command. For all MatNWB classes and functions, we use the Matlab 
% method of entering keyword argument pairs, where arguments are entered as name 
% followed by value. Ellipses are used for clarity.

nwb = NwbFile( ...
    'session_description', 'mouse in open exploration',...
    'identifier', 'Mouse5_Day3', ...
    'session_start_time', datetime(2018, 4, 25, 2, 30, 3, 'TimeZone', 'local'), ...
    'general_experimenter', 'Last, First', ... % optional
    'general_session_id', 'session_1234', ... % optional
    'general_institution', 'University of My Institution', ... % optional
    'general_related_publications', {'DOI:10.1016/j.neuron.2016.12.011'}); % optional
nwb
%% Subject Information
% You can also provide information about your subject in the NWB file. Create 
% a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Subject.html 
% |*Subject*|> object to store information such as age, species, genotype, sex, 
% and a freeform description. Then set |*nwb.general_subject*| to the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Subject.html 
% |*Subject*|> object.
% 
% 
% 
% Each of these fields is free-form, so any values will be valid, but here are 
% our recommendations:
%% 
% * For |age|, we recommend using the <https://en.wikipedia.org/wiki/ISO_8601#Durations 
% ISO 8601 Duration format>
% * For |species|, we recommend using the formal latin binomal name (e.g. mouse 
% -> _Mus musculus_, human -> _Homo sapiens_)
% * For |sex|, we recommend using F (female), M (male), U (unknown), and O (other)

subject = types.core.Subject( ...
    'subject_id', '001', ...
    'age', 'P90D', ...
    'description', 'mouse 5', ...
    'species', 'Mus musculus', ...
    'sex', 'M' ...
);
nwb.general_subject = subject;

subject
%% 
% Note: the DANDI archive requires all NWB files to have a subject object with 
% subject_id specified, and strongly encourages specifying the other fields.
%% Time Series Data
% <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeSeries.html 
% |*TimeSeries*|> is a common base class for measurements sampled over time, and 
% provides fields for |data| and |timestamps| (regularly or irregularly sampled). 
% You will also need to supply the |name| and |unit| of measurement (<https://en.wikipedia.org/wiki/International_System_of_Units 
% SI unit>).
% 
% 
% 
% For instance, we can store a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeSeries.html 
% |*TimeSeries*|> data where recording started |0.0| seconds after |start_time| 
% and sampled every second (1 Hz):

time_series_with_rate = types.core.TimeSeries( ...
    'description', 'an example time series', ...
    'data', linspace(0, 100, 10), ...
    'data_unit', 'm', ...
    'starting_time', 0.0, ...
    'starting_time_rate', 1.0);
%% 
% For irregularly sampled recordings, we need to provide the |timestamps| for 
% the |data|:

time_series_with_timestamps = types.core.TimeSeries( ...
    'description', 'an example time series', ...
    'data', linspace(0, 100, 10), ...
    'data_unit', 'm', ...
    'timestamps', linspace(0, 1, 10));
%% 
% The <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeSeries.html 
% |*TimeSeries*|> class serves as the foundation for all other time series types 
% in the NWB format. Several specialized subclasses extend the functionality of 
% <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeSeries.html 
% |*TimeSeries*|>, each tailored to handle specific kinds of data. In the next 
% section, we’ll explore one of these specialized types. For a full overview, 
% please check out the <https://nwb-schema.readthedocs.io/en/latest/format.html#type-hierarchy 
% type hierarchy> in the NWB schema documentation.
%% Other Types of Time Series 
% As mentioned previously, there are many subtypes of <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeSeries.html 
% |*TimeSeries*|> in MatNWB that are used to store different kinds of data. One 
% example is <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/AnnotationSeries.html 
% |*AnnotationSeries*|>, a subclass of <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeSeries.html 
% |*TimeSeries*|> that stores text-based records about the experiment. Similar 
% to our <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeSeries.html 
% |*TimeSeries*|> example above, we can create an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/AnnotationSeries.html 
% |*AnnotationSeries*|> object with text information about a stimulus and add 
% it to the stimulus_presentation group in the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/NWBFile.html 
% |*NWBFile*|>. Below is an example where we create an AnnotationSeries object 
% with annotations for airpuff stimuli and add it to the NWBFile.

% Create an AnnotationSeries object with annotations for airpuff stimuli
annotations = types.core.AnnotationSeries( ...
    'description', 'Airpuff events delivered to the animal', ...
    'data', {'Left Airpuff', 'Right Airpuff', 'Right Airpuff'}, ...
    'timestamps', [1.0, 3.0, 8.0] ...
);

% Add the AnnotationSeries to the NWBFile's stimulus group
nwb.stimulus_presentation.set('Airpuffs', annotations)
%% Behavior
% SpatialSeries and Position
% Many types of data have special data types in NWB. To store the spatial position 
% of a subject, we will use the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpatialSeries.html 
% |*SpatialSeries*|> and <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Position.html 
% |*Position*|> classes. 
% 
% 
% 
% Note: These diagrams follow a standard convention called "UML class diagram" 
% to express the object-oriented relationships between NWB classes. For our purposes, 
% all you need to know is that an open triangle means "extends" (i.e., is a specialized 
% subtype of), and an open diamond means "is contained within." Learn more about 
% class diagrams on <https://en.wikipedia.org/wiki/Class_diagram the wikipedia 
% page>.
% 
% <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpatialSeries.html 
% |*SpatialSeries*|> is a subclass of <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeSeries.html 
% |*TimeSeries*|>, a common base class for measurements sampled over time, and 
% provides fields for data and time (regularly or irregularly sampled). Here, 
% we put a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpatialSeries.html 
% |*SpatialSeries*|> object called |'SpatialSeries'| in a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Position.html 
% |*Position*|> object. If the data is sampled at a regular interval, it is recommended 
% to specify the |starting_time| and the sampling rate (|starting_time_rate|), 
% although it is still possible to specify |timestamps| as in the |*time_series_with_timestamps*| 
% example above.

% create SpatialSeries object
spatial_series_ts = types.core.SpatialSeries( ...
    'data', [linspace(0,10,100); linspace(0,8,100)], ...
    'reference_frame', '(0,0) is bottom left corner', ...
    'starting_time', 0, ...
    'starting_time_rate', 200 ...
);

% create Position object and add SpatialSeries
position = types.core.Position('SpatialSeries', spatial_series_ts);
%% 
% NWB differentiates between raw, _acquired_ data, which should never change, 
% and _processed_ data, which are the results of preprocessing algorithms and 
% could change. Let's assume that the animal's position was computed from a video 
% tracking algorithm, so it would be classified as processed data. Since processed 
% data can be very diverse, NWB allows us to create processing modules, which 
% are like folders, to store related processed data or data that comes from a 
% single algorithm. 
% 
% Create a processing module called "behavior" for storing behavioral data in 
% the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/NWBFile.html 
% |*NWBFile*|> and add the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Position.html 
% |*Position*|> object to the module.

% create processing module
behavior_module = types.core.ProcessingModule('description', 'contains behavioral data');

% add the Position object (that holds the SpatialSeries object) to the module 
% and name the Position object "Position"
behavior_module.nwbdatainterface.set('Position', position);

% add the processing module to the NWBFile object, and name the processing module "behavior"
nwb.processing.set('behavior', behavior_module);
% Trials
% Trials are stored in a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeIntervals.html 
% |*TimeIntervals*|> object which is a subclass of <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+hdmf_common/DynamicTable.html 
% |*DynamicTable*|>. <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+hdmf_common/DynamicTable.html 
% |*DynamicTable*|> objects are used to store tabular metadata throughout NWB, 
% including for trials, electrodes, and sorted units. They offer flexibility for 
% tabular data by allowing required columns, optional columns, and custom columns.
% 
% 
% 
% The trials <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+hdmf_common/DynamicTable.html 
% |*DynamicTable*|> can be thought of as a table with this structure:
% 
% 
% 
% Trials are stored in a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeIntervals.html 
% |*TimeIntervals*|> object which subclasses <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+hdmf_common/DynamicTable.html 
% |*DynamicTable*|>. Here, we are adding |'correct'|, which will be a logical 
% array.

trials = types.core.TimeIntervals( ...
    'colnames', {'start_time', 'stop_time', 'correct'}, ...
    'description', 'trial data and properties');

trials.addRow('start_time', 0.1, 'stop_time', 1.0, 'correct', false)
trials.addRow('start_time', 1.5, 'stop_time', 2.0, 'correct', true)
trials.addRow('start_time', 2.5, 'stop_time', 3.0, 'correct', false)

trials.toTable() % visualize the table
nwb.intervals_trials = trials;

% If you have multiple trials tables, you will need to use custom names for
% each one:
nwb.intervals.set('custom_intervals_table_name', trials);
%% Write
% Now, to write the NWB file that we have built so far:

nwbExport(nwb, 'intro_tutorial.nwb')
%% 
% We can use the <https://www.hdfgroup.org/downloads/hdfview/ HDFView> application 
% to inspect the resulting NWB file.
% 
% 
%% Read
% We can then read the file back in using MatNWB and inspect its contents. 

read_nwbfile = nwbRead('intro_tutorial.nwb', 'ignorecache')
%% 
% We can print the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpatialSeries.html 
% |*SpatialSeries*|> data traversing the hierarchy of objects. The processing 
% module called |'behavior'| contains our <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Position.html 
% |*Position*|> object named |'Position'|. The <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Position.html 
% |*Position*|> object contains our <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpatialSeries.html 
% |*SpatialSeries*|> object named |'SpatialSeries'|.

read_spatial_series = read_nwbfile.processing.get('behavior'). ...
    nwbdatainterface.get('Position').spatialseries.get('SpatialSeries')
% Reading Data
% Counter to normal MATLAB workflow, data arrays are read passively from the 
% file. Calling |*read_spatial_series.data*| does not read the data values, but 
% presents a |*DataStub*| object that can be indexed to read data. 

read_spatial_series.data
%% 
% This allows you to conveniently work with datasets that are too large to fit 
% in RAM all at once. Access all the data in the matrix using the |*load*| method 
% with no arguments. 

read_spatial_series.data.load
%% 
% If you only need a section of the data, you can read only that section by 
% indexing the |*DataStub*| object like a normal array in MATLAB. This will just 
% read the selected region from disk into RAM. This technique is particularly 
% useful if you are dealing with a large dataset that is too big to fit entirely 
% into your available RAM.

read_spatial_series.data(:, 1:10)
%% Next Steps
% This concludes the introductory tutorial. Please proceed to one of the specialized 
% tutorials, which are designed to follow this one.
%% 
% * <./ecephys.mlx Extracellular electrophysiology>
% * <./icephys.mlx Intracellular electrophysiology>
% * <./ophys.mlx Optical physiology>
%% 
% See the <https://neurodatawithoutborders.github.io/matnwb/doc/index.html API 
% documentation> to learn what data types are available.
% 
%