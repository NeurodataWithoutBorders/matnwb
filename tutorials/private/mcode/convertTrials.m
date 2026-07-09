%% NWB File Conversion Tutorial
% This tutorial shows how to convert trial-based experimental data to the Neurodata 
% Without Borders file format using MatNWB. The example uses the <https://crcns.org/data-sets/motor-cortex/alm-3 
% CRCNS ALM-3> dataset. Information on how to download the data can be found on 
% the <https://crcns.org/data-sets/motor-cortex/download CRCNS Download Page>. 
% One should first familiarize themselves with the file format, which can be found 
% on the <https://crcns.org/data-sets/motor-cortex/alm-3/about-alm-3 ALM-3 About 
% Page> under the Documentation files.
% 
% *Author*: Lawrence Niu 
% 
% *Contact*: <mailto:lawrence@vidriotech.com lawrence@vidriotech.com> 
% 
% *Last updated*: July 6, 2026
%% Script Configuration
% The following section describes the dataset identifiers and the file organization 
% and names needed to read the original data.

animal = 'ANM255201';
session = '20141124';

identifier = [animal '_' session];
%% 
% The animal and session specifiers can be changed to fit any of the available 
% sessions.
% The ALM-3 File Structure
% Each ALM-3 session has three files: a metadata .mat file describing the experiment, 
% a data structures .mat file containing processed data, and a raw .tar archive 
% containing multiple raw electrophysiology data separated by trials as .mat files. 
% All files will be merged into a single NWB file.

% Specify the local path for the downloaded data:
alm3_dataset_rootpath = getenv('CRCNS_ALM3_ROOT_PATH'); % Uses current directory if not set
data_root_path = fullfile(alm3_dataset_rootpath, 'data');

metadata_loc = fullfile(data_root_path, 'metadata', ['meta_data_' identifier '.mat']);
datastructure_loc = fullfile(data_root_path, 'data_structure_files', ...
    ['data_structure_' identifier '.mat']);
rawdata_loc = fullfile(data_root_path, 'RawVoltageTraces', [identifier '.tar']);

assert(isfile(metadata_loc) && isfile(datastructure_loc) && isfile(rawdata_loc), ...
    'Dataset files (metadata, processed and raw) were not found.')
%% 
% |metadata_loc|, |datastructure_loc|, and |rawdata_loc| should refer to the 
% metadata .mat file, the data structure .mat file, and the raw .tar file.
%% Create NWB File and Fill Out General Information

nwb = NwbFile();
nwb.identifier = identifier;
nwb.general_source_script = "matnwb/tutorials/convertTrials.mlx";
nwb.general_source_script_file_name = "matnwb/tutorials/convertTrials.mlx";
nwb.general_lab = 'Svoboda';
nwb.general_keywords = {'Network models', 'Premotor cortex', 'Short-term memory'};
nwb.general_institution = ['Janelia Research Campus,'...
    ' Howard Huges Medical Institute, Ashburn, Virginia 20147, USA'];
nwb.general_related_publications = ...
    ['Li N, Daie K, Svoboda K, Druckmann S (2016).', ...
    ' Robust neuronal dynamics in premotor cortex during motor planning.', ...
    ' Nature. 7600:459-64. doi: 10.1038/nature17643'];
nwb.general_stimulus = 'photostim';
nwb.general_protocol = 'IACUC';
nwb.general_surgery = ['Mice were prepared for photoinhibition and ', ...
    'electrophysiology with a clear-skull cap and a headpost. ', ...
    'The scalp and periosteum over the dorsal surface of the skull were removed. ', ...
    'A layer of cyanoacrylate adhesive (Krazy glue, Elmer''s Products Inc.) ', ...
    'was directly applied to the intact skull. A custom made headpost ', ...
    'was placed on the skull with its anterior edge aligned with the suture lambda ', ...
    '(approximately over cerebellum) and cemented in place ', ...
    'with clear dental acrylic (Lang Dental Jet Repair Acrylic; 1223-clear). ', ...
    'A thin layer of clear dental acrylic was applied over the cyanoacrylate adhesive ', ...
    'covering the entire exposed skull, ', ...
    'followed by a thin layer of clear nail polish (Electron Microscopy Sciences, 72180).'];
nwb.session_description = sprintf('Animal `%s` on Session `%s`', animal, session);
%% 
% All properties with the prefix |general| contain context for the entire experiment 
% such as lab, institution, and experimentors. For session-delimited data from 
% the same experiment, these fields will all be the same. Note that most of this 
% information was pulled from the publishing paper and not from any of the downloadable 
% data.
% 
% The only required property is the |identifier|, which distinguishes one session 
% from another within an experiment. In our case, the ALM-3 data uses a combination 
% of session date and animal ID.
%% Add Metadata
% ALM-3 Metadata contains information about the reference times, experimental 
% context, methodology, as well as details of the electrophysiology, optophysiology, 
% and behavioral portions of the experiment. A vast majority of these details 
% are placed in |general| prefixed properties in NWB.

relative_metadata_loc = strrep(metadata_loc, alm3_dataset_rootpath, '');
fprintf('Processing metadata from `%s`\n', relative_metadata_loc);
loaded = load(metadata_loc, 'meta_data');
meta = loaded.meta_data;

% Experiment-specific treatment for animals with the ReaChR gene modification
isreachr = any(cell2mat(strfind(meta.animalGeneModification, 'ReaChR')));

% Sessions are separated by date of experiment.
nwb.general_session_id = meta.dateOfExperiment;

% ALM-3 data start time is equivalent to the reference time.
nwb.session_start_time = datetime([meta.dateOfExperiment meta.timeOfExperiment], ...
    'InputFormat', 'yyyyMMddHHmmss', 'TimeZone', 'America/New_York'); % Eastern Daylight Time
nwb.timestamps_reference_time = nwb.session_start_time;

nwb.general_experimenter = strjoin(meta.experimenters, ', ');
%%
nwb.general_subject = types.core.Subject( ...
    'species', meta.species{1}, ...
    'subject_id', meta.animalID{1}(1,:), ... %weird case with duplicate Animal ID
    'sex', upper(meta.sex), ... % NWB Best practice: 'M' (male), 'F' (female), 'O' (other), or 'U' (unknown).
    'age', meta.dateOfBirth, ... % evaluated to 'not recorded' for example session.
    'description', [...
        'Whisker Config: ' strjoin(meta.whiskerConfig, ', ') newline...
        'Animal Source: ' strjoin(meta.animalSource, ', ')]);
%% 
% Ideally, if a raw data field does not correspond directly to a NWB field, 
% one would create their own using a <https://pynwb.readthedocs.io/en/latest/extensions.html 
% custom NWB extension class>. However, since these fields are mostly experimental 
% annotations, we instead pack the extra values into the |description| field as 
% a string.

% The formatStruct function simply prints the field and values given the struct.
% An optional cell array of field names specifies whitelist of fields to print. 
% This function is provided with this script in the tutorials directory.
nwb.general_subject.genotype = formatStruct( ...
    meta, ...
    {'animalStrain'; 'animalGeneModification'; 'animalGeneCopy';...
    'animalGeneticBackground'});

weight = {};
if ~isempty(meta.weightBefore)
    weight{end+1} = 'weightBefore';
end
if ~isempty(meta.weightAfter)
    weight{end+1} = 'weightAfter';
end
weight = weight(~cellfun('isempty', weight));
if ~isempty(weight)
    nwb.general_subject.weight = formatStruct(meta, weight);
end

% general/experiment_description
nwb.general_experiment_description = [...
    formatStruct(meta, {'experimentType'; 'referenceAtlas'}), ...
    newline, ...
    formatStruct(meta.behavior, {'task_keyword'})];

% Miscellaneous collection information from ALM-3 that didn't quite fit any NWB 
% properties are stored in general/data_collection.
nwb.general_data_collection = formatStruct(meta.extracellular, ...
    {'extracellularDataType';'cellType';'identificationMethod';'amplifierRolloff';...
    'spikeSorting';'ADunit'});

% Add Devices
% We store information about the multichannel silicon probe and the optogenetic 
% stimulation laser using |*DeviceModel*| and |*Device*| objects.

% Create a device model for the silicon probe
siliconProbeModel = types.core.DeviceModel( ...
    'manufacturer', meta.extracellular.probeSource{1}, ...
    'model_number', meta.extracellular.probeType{1}, ...
    'description', '32-channel silicon depth probe');
nwb.general_devices_models.set('SiliconProbeModel', siliconProbeModel);

% Create a specific device for the silicon probe used in this 
% experiment. A serial number can be added to the 'serial_number' 
% property if present.
siliconProbe = types.core.Device('model', siliconProbeModel, ...
    'description', siliconProbeModel.description);
nwb.general_devices.set('SiliconProbe', siliconProbe);

% Create a device model for the stimulation laser
if isreachr
    laserModel = types.core.DeviceModel( ...
        'manufacturer', 'Cobolt Inc.', ...
        'model_number', 'Cobolt Mambo 100', ...
        'description', ['Continuous-wave solid-state laser operating ', ...
                        'at a fixed wavelength 594 nm']);
    laserName = 'Laser594nm';
else
    laserModel = types.core.DeviceModel( ...
        'manufacturer', 'Laser Quantum', ...
        'model_number', 'Gem 473', ...
        'description', ['Continuous-wave solid-state laser operating ', ...
                        'at a fixed wavelength 473 nm']);
    laserName = 'Laser473nm';
end
nwb.general_devices_models.set('LaserModel', laserModel);

% Create a specific device for the laser used in this experiment.
laser = types.core.Device('model', laserModel, ...
    'description', laserModel.description);
nwb.general_devices.set(laserName, laser);
% Add Electrode Group

structDesc = {'recordingCoordinates';'recordingMarker';'recordingType';'penetrationN';...
    'groundCoordinates'};
if ~isempty(meta.extracellular.referenceCoordinates)
    structDesc{end+1} = 'referenceCoordinates';
end
recordingLocation = meta.extracellular.recordingLocation{1};
electrodeGroup = types.core.ElectrodeGroup( ...
    'description', formatStruct(meta.extracellular, structDesc), ...
    'location', recordingLocation, ...
    'device', types.untyped.SoftLink(siliconProbe));
nwb.general_extracellular_ephys.set('ElectrodeGroup', electrodeGroup);
%% 
% The NWB *ElectrodeGroup* object stores experimental information regarding 
% a group of probes. Doing so requires a *SoftLink* to the silicon probe previously 
% specified under |general_devices|. |SoftLink| objects are direct maps to <https://portal.hdfgroup.org/display/HDF5/H5L_CREATE_SOFT 
% HDF5 Soft Links> on export.
% Add Electrodes Table
% We create an electrodes table for representing each channel from the silicon 
% probe.

% Initialize a table with 0-row VectorData objects for each column, using
% name-value arguments in the ElectrodesTable constructor.
dtColNames = {'x', 'y', 'z', 'imp', 'location', 'filtering','group', 'group_name'};
electrodesTable = types.core.ElectrodesTable( ...
    'colnames', dtColNames, ...
    'description', 'Electrode channels', ...
    'x', types.hdmf_common.VectorData('description', 'x coordinate of the channel location in the brain (+x is posterior).'), ...
    'y', types.hdmf_common.VectorData('description', 'y coordinate of the channel location in the brain (+y is inferior).'), ...
    'z', types.hdmf_common.VectorData('description', 'z coordinate of the channel location in the brain (+z is right).'), ...
    'imp', types.hdmf_common.VectorData('description', 'Impedance of the channel.'), ...
    'location', types.hdmf_common.VectorData('description', ['Location of the electrode (channel). '...
    'Specify the area, layer, comments on estimation of area/layer, stereotaxic coordinates if '...
    'in vivo, etc. Use standard atlas names for anatomical regions when possible.']), ...
    'filtering', types.hdmf_common.VectorData('description', 'Description of hardware filtering.'), ...
    'group', types.hdmf_common.VectorData('description', 'Reference to the ElectrodeGroup this electrode is a part of.'), ...
    'group_name', types.hdmf_common.VectorData('description', 'Name of the ElectrodeGroup this electrode is a part of.'));

% All electrodes channels are part of the same electrode group
eGroupReference = types.untyped.ObjectView(electrodeGroup);

% Add electrodes one by one using the `addRow` method. The `id` column 
% is populated automatically if not provided.
for i = 1:length(meta.extracellular.siteLocations)
    location = meta.extracellular.siteLocations{i};
    electrodesTable.addRow( ...
        'x', location(1), 'y', location(2), 'z', location(3), ...
        'imp', 0, ...
        'location', recordingLocation, ...
        'filtering', '', ...
        'group', eGroupReference, ...
        'group_name', meta.extracellular.probeType{1});
end
%% 
% The |group| column in the |*ElectrodesTable*| contains an *ObjectView* to 
% the previously created |*ElectrodeGroup*|. An |*ObjectView*| can be best thought 
% of as a direct pointer to another typed object. It also directly maps to a <https://portal.hdfgroup.org/display/HDF5/H5R_CREATE 
% HDF5 Object Reference>. |*ObjectViews*| are slightly different from |*SoftLinks*| 
% in that they can be stored in datasets (data columns, tables, and |data| fields 
% in |NWBData| objects).

% Add the electrodes table to the NWB file
nwb.general_extracellular_ephys_electrodes = electrodesTable;
%% 
% The |electrodes| property in |extracellular_ephys| is a special keyword in 
% NWB that must be paired with a |*ElectrodesTable*|. These are tables which can 
% have an unbounded number of columns and rows, each as their own dataset. With 
% the exception of the |id| column, all other columns must be *VectorData* or 
% *VectorIndex* objects. The |id| column, meanwhile, must be an *ElementIdentifiers* 
% object. The names of all used columns are specified in the in the |colnames| 
% property as a cell array of strings.
% Add Optogenetic Stimulus Site
% Add information about optogenetic stimulation using the |*OptogeneticStimulusSite*| 
% class.

photoStim = types.core.OptogeneticStimulusSite( ...
    'excitation_lambda', meta.photostim.photostimWavelength{1}, ...
    'location', meta.photostim.photostimLocation{1}, ...
    'device', types.untyped.SoftLink(laser), ...
    'description', formatStruct(meta.photostim, {...
    'stimulationMethod';'photostimCoordinates';'identificationMethod'}));
nwb.general_optogenetics.set('photostim', photoStim);
%% Processed Data Structure
% The ALM-3 data structures .mat file contains processed spike data, trial-specific 
% parameters, and behavioral data.

% Load processed data from the datastructure file
relative_datastructure_loc = strrep(datastructure_loc, alm3_dataset_rootpath, '');
fprintf('Processing Data Structure `%s`\n', relative_datastructure_loc);
loaded = load(datastructure_loc, 'obj');
data = loaded.obj;

% Append 's' to match NWBs preferred units format for time units, i.e., second->seconds
data.timeUnitNames = strcat(data.timeUnitNames, 's') 
% Hashes
% ALM-3 stores its data structures in the form of *hashes* which are essentially 
% the same as python's dictionaries or MATLAB's maps but where the keys and values 
% are stored under separate struct fields. Getting a hashed value from a key involves 
% retrieving the array index that the key is in and applying it to the parallel 
% array in the values field.
% 
% You can find more information about hashes and how they're used on the <https://crcns.org/data-sets/motor-cortex/alm-3/about-alm-3 
% ALM-3 about page>.
% Add Recorded Behavioral Timeseries Data
% First we extract time series data recorded by the Ephus software and add to 
% the NWB file.

ephusTimeseriesData = data.timeSeriesArrayHash.value{1};
ephusTimeUnit = data.timeUnitNames{data.timeUnitIds(ephusTimeseriesData.timeUnit)};

% 1. Lick direction trace
tsIdx = strcmp(ephusTimeseriesData.idStr, 'lick_trace');
lickTrace = types.core.TimeSeries( ...
    'data', ephusTimeseriesData.valueMatrix(:,tsIdx), ...
    'data_unit', 'n/a', ...
    'description', ephusTimeseriesData.idStrDetailed{tsIdx}, ...
    'timestamps', ephusTimeseriesData.time, ...
    'timestamps_unit', ephusTimeUnit);
bts = types.core.BehavioralTimeSeries('lick_trace_ts', lickTrace);
nwb.acquisition.set('lick_trace', bts);

% 2. Acousto-optic modulator input trace
tsIdx = strcmp(ephusTimeseriesData.idStr, 'aom_input_trace');
aomInputTrace = types.core.TimeSeries( ...
    'data', ephusTimeseriesData.valueMatrix(:,tsIdx), ...
    'data_unit', 'volts', ...
    'description', ephusTimeseriesData.idStrDetailed{tsIdx}, ...
    'timestamps', ephusTimeseriesData.time, ...
    'timestamps_unit', ephusTimeUnit);
nwb.stimulus_presentation.set('aom_input_trace', aomInputTrace);

% 3. Laser power delivered in tissue
tsIdx = strcmp(ephusTimeseriesData.idStr, 'laser_power');
laserPowerTrace = types.core.OptogeneticSeries( ...
    'data', ephusTimeseriesData.valueMatrix(:, tsIdx), ...
    'data_conversion', 1e-3, ... % data is stored in mW, data unit for OptogeneticSeries is watts
    'description', ephusTimeseriesData.idStrDetailed{tsIdx}, ...
    'timestamps', ephusTimeseriesData.time, ...
    'timestamps_unit', ephusTimeUnit, ...
    'site', types.untyped.SoftLink(photoStim));
nwb.stimulus_presentation.set('laser_power', laserPowerTrace);
% Build Trials Table (TimeIntervals)
% The sessions of the ALM-3 dataset has a trial-based structure. We will build 
% a trials table using the |*TimeIntervals*| class, a subclass of the |*DynamicTable*|, 
% to represent this trial structure. The |*TimeIntervals*| requires a |start_time| 
% and a |stop_time| for each row. It also supports adding references to the portion 
% of one or more time series that belong to a given trial. We will add time series 
% references below, but we start by adding dataset-specific trial information. 
% Because of how the original data is structured, we will build the trials table 
% column-by-column using the |addColumn| method.

% Initialize the trials table with start times and trial ids
trial_intervals = types.core.TimeIntervals( ...
    'colnames', {'start_time'}, ...
    'description', 'Trial data and properties', ...
    'start_time', types.hdmf_common.VectorData( ...
        'data', data.trialStartTimes', ... % transpose to add data as a column vector
        'description', 'Start time of epoch, in seconds.'), ...
    'id', types.hdmf_common.ElementIdentifiers( ...
        'data', data.trialIds' ) );

% Add columns for the trial types. These are all boolean state.
for i = 1:length(data.trialTypeStr)
    columnName = data.trialTypeStr{i};
    columnData = types.hdmf_common.VectorData( ...
         'data', logical(data.trialTypeMat(i,:))', ... % transpose for column vector 
         'description', data.trialTypeStr{i});
    trial_intervals.addColumn( columnName, columnData )
end

% Add columns for the trial properties
for i = 1:length(data.trialPropertiesHash.keyNames)
    columnName = data.trialPropertiesHash.keyNames{i};
    descr = data.trialPropertiesHash.descr{i};
    if iscellstr(descr) || isstring(descr)
        descr = strjoin(descr, newline);
    end
    columnData = types.hdmf_common.VectorData( ...
         'data', data.trialPropertiesHash.value{i}, ...
         'description', descr);
    trial_intervals.addColumn( columnName, columnData )
end

% Add trial_intervals to the 'intervals_trials' property of the NWB file.
nwb.intervals_trials = trial_intervals;

% Display the trials table
nwb.intervals_trials.toTable()
% Build Trial-Aligned Timeseries References
% The |timeseries| property of the |*TimeIntervals*| object is an example of 
% a *compound data type* containing the following fields: a |timeseries| (an *ObjectView* 
% reference to a time series), an |idx_start| (the index of the target TimeSeries' 
% data/timestamps dataset corresponding to when the trial started) and a |count| 
% (the number of samples of the time series' data/timestamps that are part of 
% the trial interval). These types are essentially tables of data in HDF5 and 
% can be represented by a MATLAB table, an array of structs, or a struct of arrays. 
% Beware: validation of column lengths here is not guaranteed by the type checker 
% until export.

% Initialize a cell array for references where each cell represents one trial.
trial_timeseries = cell(size(data.trialIds)); 

% Create ObjectView references for each of the TimeSeries we added above.
lick_trace_reference = types.untyped.ObjectView(lickTrace);
aom_input_trace_reference = types.untyped.ObjectView(aomInputTrace);
laser_power_ref = types.untyped.ObjectView(laserPowerTrace);

% Append trials timeseries references in order. We must populate this way 
% because trials may not be in trial order.
[ephus_trials, ~, trials_to_data] = unique(ephusTimeseriesData.trial);
for i = 1:length(ephus_trials)
    i_loc = i == trials_to_data;
    t_start = find(i_loc, 1);
    t_count = sum(i_loc);
    trial = ephus_trials(i);
    
    trial_timeseries{trial}(end+(1:3), :) = {...
        lick_trace_reference int64(t_start) int64(t_count);...
        aom_input_trace_reference  int64(t_start) int64(t_count);...
        laser_power_ref int64(t_start) int64(t_count)};
end
%% Add timeseries to trial_intervals
% Because we are adding more than one timeseries reference per trial, we need 
% to add these references to the |*TimeIntervals*| table as a <https://nwb-schema.readthedocs.io/en/latest/format_description.html#tables-and-ragged-arrays 
% ragged array>. That means that we need to create a |*TimeSeriesReferenceVectorData*| 
% object to represent the references and a |*VectorIndex*| object to map these 
% references to their respective trials (rows). Each element in the |*VectorIndex*| 
% marks the *last* element in the corresponding |*VectorData*| object for the 
% *VectorIndex* row. Thus, the starting index for this row would be the previous 
% index + 1. You can see this in effect with the |timeseries| property which is 
% indexed by the |timeseries_index| property.

ts_len = cellfun('size', trial_timeseries, 1);

% Intervals/trials/timeseries is a compound type so we use cell2table to
% convert this 2-d cell array into a compatible table.
is_len_nonzero = ts_len > 0;
trial_timeseries_table = cell2table(vertcat(trial_timeseries{is_len_nonzero}), ...
    'VariableNames', {'timeseries', 'idx_start', 'count'});
trial_timeseries_table = movevars(trial_timeseries_table, 'timeseries', 'After', 'count');

interval_trials_timeseries = types.core.TimeSeriesReferenceVectorData( ...
    'description', 'References to portions of timeseries data corresponding to trial intervals', ...
    'data', trial_timeseries_table);
nwb.intervals_trials.timeseries = interval_trials_timeseries;

nwb.intervals_trials.timeseries_index = types.hdmf_common.VectorIndex( ...
    'description', 'Index into Timeseries VectorData', ...
    'data', cumsum(ts_len)', ...
    'target', types.untyped.ObjectView(interval_trials_timeseries) );
% Adding Units
% Ephus spike data is separated into units which directly maps to the NWB property 
% of the same name. Each such unit contains a group of extracted waveforms and 
% spike times, all linked to a different subset of trials IDs. We create a |Units| 
% table for storing spike times and waveforms per unit.

nwb.units = types.core.Units('colnames', ...
    {'spike_times', 'trials', 'electrodes', 'cell_type'}, ...
    'description', 'Extracted spike events', ...
    'electrodes', types.hdmf_common.DynamicTableRegion( ...
        'description', 'Electrodes which units were detected from', ...
        'table', types.untyped.ObjectView(electrodesTable), ...
        'data', []), ...
    'spike_times', types.hdmf_common.VectorData( ...
        'description', 'timestamps of spikes') ...
    );

esHash = data.eventSeriesHash;
unitIds = regexp(esHash.keyNames, '^unit(\d+)$', 'once', 'tokens');
unitIds = str2double([unitIds{:}]);

[waveform_means, waveform_stds, waveform_snippets] = deal(cell(1, numel(unitIds)));

for i = 1:length(unitIds)
    esData = esHash.value{i};
    
    % Add trials ID reference
    good_trials_mask = ismember(esData.eventTrials, nwb.intervals_trials.id.data);
    eventTrials = esData.eventTrials(good_trials_mask);
    eventTimes = esData.eventTimes(good_trials_mask);
    waveforms = esData.waveforms(good_trials_mask,:);
    channel = esData.channel(good_trials_mask);
    
    assert(strcmp(data.timeUnitNames{data.timeUnitIds(esData.timeUnit)}, 'seconds'), ...
        'Expected time unit for spike event series data to be second')

    if ~isempty(esData.cellType)
        cellType = esData.cellType{1};
    else
        cellType = 'n/a';
    end

    nwb.units.addRow( ...
        'id', unitIds(i), ...
        'trials', eventTrials, ...
        'spike_times', eventTimes, ...
        'electrodes', unique(channel) - 1, ...
        'cell_type', cellType);

    % Collect waveform snippets and per unit event count for 
    % building nested ragged vector.
    waveform_snippets{i} = waveforms; % [numWaveforms x numSamples]

    % Collect this unit's mean and std waveform; 
    % added as a column after the loop.
    waveform_means{i} = mean(waveforms, 1).'; % [nSamples x 1]
    waveform_stds{i} = std(waveforms, 0, 1).'; % [nSamples x 1]
end

nwb.units.addDoublyRaggedArray(...
    'waveforms', waveform_snippets, ...
    'description', 'Spike waveforms for each unit')
nwb.units.waveforms_sampling_rate = 19531.25; % from data descriptor

% Add the per-unit mean waveforms as a single fixed-shape column. Building it
% here (rather than via addRow) keeps waveform_mean as a plain 2-D dataset
% ([nUnits x nSamples] on disk, no index), as required by the schema.
nwb.units.waveform_mean = types.hdmf_common.VectorData( ...
    'description', 'Mean spike waveform for each unit', ...
    'data', [waveform_means{:}]); % [numSamples x numUnits]

% Repeat for waveform_std
nwb.units.waveform_sd = types.hdmf_common.VectorData( ...
    'description', 'Standard deviation of spike waveform for each unit', ...
    'data', [waveform_stds{:}]); % [numSamples x numUnits]
%% 
% To better understand how |spike_times_index| and |spike_times| map to each 
% other, refer to <https://neurodatawithoutborders.github.io/matnwb/tutorials/html/ecephys.html#13 
% this diagram> from the Extracellular Electrophysiology Tutorial. 
% 
% Also note: if a unit was present on more than one electrode, each spike has 
% one waveform _per electrode_. In that case, build each unit's entry as a nested 
% cell — |data{unit}{spike}| a |[numElectrodes x numSamples]| matrix (one row 
% per electrode) — and pass it to |addDoublyRaggedArray|. The row order must match 
% the electrodes listed in that unit's |electrodes| entry (as the NWB schema requires). 
% Here each unit was recorded on a single electrode, so each spike has exactly 
% one waveform and the simpler |[numSpikes x numSamples]| form used above is sufficient.
%% Raw Acquisition Data
% Each ALM-3 session is associated with a large number of raw voltage data grouped 
% by trial ID. To map this data to NWB, each trial is created as its own *ElectricalSeries* 
% object under the name 'trial n' where 'n' is the trial ID. The trials are then 
% linked to the trials table (|*TimeIntervals*|) for easy referencing.

relative_rawdata_loc = strrep(rawdata_loc, alm3_dataset_rootpath, '');
fprintf('Processing Raw Acquisition Data from `%s` (will take a while)\n', relative_rawdata_loc);
untarLoc = strrep(rawdata_loc, '.tar', '');
if ~isfolder(untarLoc)
    untar(rawdata_loc, fileparts(rawdata_loc));
end

rawfiles = dir(untarLoc);
rawfiles = fullfile(untarLoc, {rawfiles(~[rawfiles.isdir]).name});

nrows = length(nwb.general_extracellular_ephys_electrodes.id.data);
tablereg = types.hdmf_common.DynamicTableRegion( ...
    'description', 'Relevent electrodes for this electrical series', ...
    'table', types.untyped.ObjectView(electrodesTable), ...
    'data', (1:nrows) - 1);
objrefs = cell(size(rawfiles));

endTimestamps = trial_intervals.start_time.data;
for i = 1:length(rawfiles)
    tnumstr = regexp(rawfiles{i}, '_trial_(\d+)\.mat$', 'tokens', 'once');
    tnumstr = tnumstr{1};
    rawdata = load(rawfiles{i}, 'ch_MUA', 'TimeStamps');
    tnum = str2double(tnumstr);
    
    if tnum > length(endTimestamps)
        continue; % sometimes there are extra trials without an associated start time.
    end

    deltaT = diff( rawdata.TimeStamps );
    tol = 1e-6;
    if max(abs(diff(deltaT))) < tol*mean(deltaT) % Constant rate
        nvPairs = {'starting_time', rawdata.TimeStamps(1), ...
            'starting_time_rate', mean(deltaT)};
    else
        nvPairs = {'timestamps', rawdata.TimeStamps};
    end
    
    electricalSeries = types.core.ElectricalSeries( ...
        'data', transpose(rawdata.ch_MUA), ... % Must be shape: numChannels x numTimepoints
        'description', ['Raw voltage acquisition for trial ' tnumstr], ...
        'electrodes', tablereg, ...
        nvPairs{:});
    tname = ['trial ' tnumstr];
    nwb.acquisition.set(tname, electricalSeries);
    
    endTimestamps(tnum) = endTimestamps(tnum) + rawdata.TimeStamps(end);
    objrefs{tnum} = types.untyped.ObjectView(electricalSeries);
end
% Link the raw acquired data to the trials in the trials table.
% Link to the raw data by adding a column named "raw_voltage_traces" with |ObjectViews| 
% to the |ElectricalSeries| objects for the raw voltage traces.

emptyReferences = cellfun('isempty', objrefs);
objrefs(emptyReferences) = {[]};

trial_intervals.addRaggedArray('raw_voltage_traces', objrefs, ...
    'description', 'Reference to recorded (raw) electrical signals per trial');

% Finally, we also add the trials' stop_time which were extracted from the
% raw data.
trial_intervals.stop_time = types.hdmf_common.VectorData( ...
     'data', endTimestamps', ...
     'description', 'The end time of each trial');
%% 
% Note: Because each trial has a one-to-one mapping to a full |*ElectricalSeries*| 
% object, we added a separate table column with |*ObjectView*| references instead 
% of adding using the |*TimeSeriesReferenceVectorData*|, which is specialised 
% for referencing portions of |*TimeSeries*| objects.
%% Export
% Prepare the output directory:

output_directory = fullfile(alm3_dataset_rootpath, 'out');

if ~isfolder(output_directory)
    mkdir(output_directory);
end
%% 
% The NWB file will be saved in the output directory indicated by |output_directory|

nwbFilePath = fullfile(output_directory, [identifier '.nwb']);
if isfile(nwbFilePath)
    delete(nwbFilePath);
end
nwbExport(nwb, nwbFilePath);
%% Inspect the NWB file using nwbinspector
% Note: The following function assumes the nwbinspector tool is installed. See 
% `|help inspectNwbFile|`

inspectNwbFile(nwbFilePath)