%% NWB File Conversion Tutorial
% How to convert trial-based experimental data to the Neurodata Without Borders file format using MatNWB.
% This example uses the <https://crcns.org/data-sets/motor-cortex/alm-3 CRCNS ALM-3>
% data set.  Information on how to download the data can be found on the 
% <https://crcns.org/data-sets/motor-cortex/download CRCNS Download Page>.  One should
% first familiarize themselves with the file format, which can be found on the
% <https://crcns.org/data-sets/motor-cortex/alm-3/about-alm-3 ALM-3 About Page> under
% the Documentation files.
% 
%  author: Lawrence Niu
%  contact: lawrence@vidriotech.com
%  last updated: Dec 27, 2018

%% Script Configuration
% The following details configuration information specific to this script.  Parameters
% can be changed to fit any of the available sessions.
%%
% The animal and session specifier can be changed below with the *animal* and *session*
% variable name respectively.  *metadata_loc*, *datastructure_loc*, and *rawdata_loc*
% should refer to: the metadata .mat file, the data structure .mat file, 
% and the raw .tar file.
animal = 'ANM255200';
session = '20140910';

identifier = [animal '_' session];

metadata_loc = fullfile('data','metadata', ['meta_data_' identifier '.mat']);
datastructure_loc = fullfile('data','data_structure_files',...
    ['data_structure_' identifier '.mat']);
rawdata_loc = fullfile('data', 'RawVoltageTraces', [identifier '.tar']);
%%
% The NWB file will be saved in the output directory indicated by *outdir*
outloc = 'out';

if 7 ~= exist(outloc, 'dir')
    mkdir(outloc);
end

source_file = [mfilename() '.m'];
[~, source_script, ~] = fileparts(source_file);

%% General Information
% The first thing we fill out are general experiment context information.  The only
% required information here is the identifier, which distinguishes one session from
% another.  The ALM-3 data is separated by session date and experimented animal ID so
% we will do the same with our identifier.
%%
% Not all general information can be found in the data files.  Certain properties like
% keywords, institutions, and related publications were derived from the published paper.
nwb = nwbfile();
nwb.identifier = identifier;
nwb.general_source_script = source_script;
nwb.general_source_script_file_name = source_file;
nwb.general_lab = 'Svoboda';
nwb.general_keywords = {'Network models', 'Premotor cortex', 'Short-term memory'};
nwb.general_institution = ['Janelia Research Campus,'...
    ' Howard Huges Medical Institute, Ashburn, Virginia 20147, USA'];
nwb.general_related_publications = ...
    ['Li N, Daie K, Svoboda K, Druckmann S (2016).',...
    ' Robust neuronal dynamics in premotor cortex during motor planning.',...
    ' Nature. 7600:459-64. doi: 10.1038/nature17643'];
nwb.general_stimulus = 'photostim';
nwb.general_protocol = 'IACUC';
nwb.general_surgery = ['Mice were prepared for photoinhibition and ',...
    'electrophysiology with a clear-skull cap and a headpost. ',...
    'The scalp and periosteum over the dorsal surface of the skull were removed. ',...
    'A layer of cyanoacrylate adhesive (Krazy glue, Elmer’s Products Inc.) ',...
    'was directly applied to the intact skull. A custom made headpost ',...
    'was placed on the skull with its anterior edge aligned with the suture lambda ',...
    '(approximately over cerebellum) and cemented in place ',...
    'with clear dental acrylic (Lang Dental Jet Repair Acrylic; 1223-clear). ',...
    'A thin layer of clear dental acrylic was applied over the cyanoacrylate adhesive ',...
    'covering the entire exposed skull, ',...
    'followed by a thin layer of clear nail polish (Electron Microscopy Sciences, 72180).'];
nwb.session_description = sprintf('Animal `%s` on Session `%s`', animal, session);
%% File Overview
% Each session has three files: a metadata .mat file describing the experiment, the
% data structures .mat file containing trial/analysis data, and the raw data .tar
% file containing the raw electrophysiology data separated by trial.
%% Metadata
% ALM-3 Metadata contains information about the reference times, experimental context,
% methodology, as well as details of the electrophysiology, optophysiology, and behavioral
% portions of the experiment.  A vast majority of these details will be placed in the
% _general_ subgroup in NWB.
loaded = load(metadata_loc, 'meta_data');
meta = loaded.meta_data;

%experiment-specific treatment for animals with the ReaChR gene modification
isreachr = any(cell2mat(strfind(meta.animalGeneModification, 'ReaChR')));

%sessions are separated by date of experiment.
nwb.general_session_id = meta.dateOfExperiment;

%ALM-3 data start time is reference time.
nwb.session_start_time = datetime([meta.dateOfExperiment meta.timeOfExperiment],...
    'InputFormat', 'yyyyMMddHHmmss');
nwb.timestamps_reference_time = nwb.session_start_time;

nwb.general_experimenter = strjoin(meta.experimenters, ', ');

%%
% Ideally, if a raw data field does not correspond directly to a NWB field, one would
% create their own using a
% <https://pynwb.readthedocs.io/en/latest/extensions.html custom NWB extension class>.
% To keep this tutorial simple, we instead pack the extra values into the _description_
% field as a string, which works with miscellaneous configuration parameters such as these.
nwb.general_subject = types.core.Subject(...
    'species', meta.species{1}, ...
    'subject_id', meta.animalID{1}(1,:), ... %weird case with duplicate Animal ID
    'sex', meta.sex, ...
    'age', meta.dateOfBirth, ...
    'description', [...
        'Whisker Config: ' strjoin(meta.whiskerConfig, ', ') newline...
        'Animal Source: ' strjoin(meta.animalSource, ', ')]);

%formatStruct simply prints the field and values given the struct.  Optional cell
%array of field names specifies whitelist of fields to print.
nwb.general_subject.genotype = formatStruct(...
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
    sprintf('\n'), ...
    formatStruct(meta.behavior, {'task_keyword'})];

% Miscellaneous collection information from ALM-3 that didn't quite fit any NWB properties
% are stored in general/data_collection.
nwb.general_data_collection = formatStruct(meta.extracellular,...
    {'extracellularDataType';'cellType';'identificationMethod';'amplifierRolloff';...
    'spikeSorting';'ADunit'});

% Device objects are essentially just a list of device names.  We store the probe
% and laser hardware names here.
probetype = meta.extracellular.probeType{1};
probeSource = meta.extracellular.probeSource{1};
nwb.general_devices.set([probetype ' (' probeSource ')'],...
    types.core.Device());

if isreachr
    laserName = 'laser-594nm (Cobolt Inc., Cobolt Mambo 100)';
else
    laserName = 'laser-473nm (Laser Quantum, Gem 473)';
end
nwb.general_devices.set(laserName, types.core.Device());

%%
% The NWB *ElectrodeGroup* object stores experimental information regarding a group of
% probes (presumably defined in the *Device* section).  The object requires
% a *SoftLink* to the probe specified under _devices_.
% SoftLink objects are direct maps to
% <https://portal.hdfgroup.org/display/HDF5/H5L_CREATE_SOFT HDF5 Soft Links> on export,
% and thus, require a true HDF5 path.
structDesc = {'recordingCoordinates';'recordingMarker';'recordingType';'penetrationN';...
    'groundCoordinates'};
if ~isempty(meta.extracellular.referenceCoordinates)
    structDesc{end+1} = 'referenceCoordinates';
end
recordingLocation = meta.extracellular.recordingLocation{1};
egroup = types.core.ElectrodeGroup(...
    'description', formatStruct(meta.extracellular, structDesc),...
    'location', recordingLocation,...
    'device', types.untyped.SoftLink(['/general/devices/' probetype]));
nwb.general_extracellular_ephys.set(probetype, egroup);
egroupPath = ['/general/extracellular_ephys/' probetype];

%%
% The _electrodes_ property in _extracellular_ephys_ is a special keyword in NWB that
% must be paired with a *Dynamic Table*.  These are tables which can have an unbounded
% number of columns and rows, each as their own dataset.  With the exception of _id_,
% all columns must be *VectorData* or *VectorIndex* objects.  The _id_ column, meanwhile,
% must be an *ElementIdentifiers* object.
% The names of all used columns are specified in the in the _colnames_ property
% as a cell array of strings.
%%
% The _group_ column in the Dynamic Table contains an *ObjectView* to the ElectrodeGroup
% created above.  An ObjectView can be best thought of as a direct pointer to another
% typed object.  It also directly maps to a 
% <https://portal.hdfgroup.org/display/HDF5/H5R_CREATE HDF5 Object Reference>
% , thus the HDF5 path requirement.  ObjectViews are slightly different from SoftLinks
% in that they can be stored in datasets (data columns, tables, and _data_ fields in
% *NWBData* objects).
etrodeNum = length(meta.extracellular.siteLocations);
etrodeMat = cell2mat(meta.extracellular.siteLocations .');
emptyStr = repmat({''}, etrodeNum,1);
dtColNames = {'x', 'y', 'z', 'imp', 'location', 'description', 'filtering','group',...
    'group_name'};
% you can specify column names and values as key-value arguments in the DynamicTable
% constructor.
dynTable = types.core.DynamicTable(...
    'colnames', dtColNames,...
    'description', 'Electrodes',...
    'id', types.core.ElementIdentifiers('data', int64(1:etrodeNum)),...
    'x', types.core.VectorData('data', etrodeMat(:,1),...
        'description', 'the x coordinate of the channel location'),...
    'y', types.core.VectorData('data', etrodeMat(:,2),...
        'description', 'the y coordinate of the channel location'),...
    'z', types.core.VectorData('data', etrodeMat(:,3),...
        'description','the z coordinate of the channel location'),...
    'imp', types.core.VectorData('data', zeros(etrodeNum,1),...
        'description','the impedance of the channel'),...
    'location', types.core.VectorData('data',...
        repmat({recordingLocation}, etrodeNum, 1),...
        'description', 'the location of channel within the subject e.g. brain region'),...
    'filtering', types.core.VectorData('data', emptyStr,...
        'description', 'description of hardware filtering'),...
    'group', types.core.VectorData('data',...
        repmat(types.untyped.ObjectView(egroupPath), etrodeNum, 1),...
        'description', 'a reference to the ElectrodeGroup this electrode is a part of'),...
    'group_name', types.core.VectorData('data', repmat({probetype}, etrodeNum, 1),...
        'description', 'the name of the ElectrodeGroup this electrode is a part of'));
nwb.general_extracellular_ephys.set('electrodes', dynTable);
%%

% general/optogenetics/photostim
nwb.general_optogenetics.set('photostim', ...
    types.core.OptogeneticStimulusSite(...
    'excitation_lambda', num2str(meta.photostim.photostimWavelength{1}), ...
    'location', meta.photostim.photostimLocation{1}, ...
    'device', laserName, ...
    'description', formatStruct(meta.photostim, {...
    'stimulationMethod';'photostimCoordinates';'identificationMethod'})));

%% Data Structures and Hashes
% ALM-3 stores its data structures in the form of *Hashes* which are essentially the
% same as Dictionaries or containers.Maps but where the keys and values are stored
% under separate struct fields.  Getting a "hashed" value from a key involves retrieving
% the array index that the key is in and applying it to the parallel array in the values
% field.  In that way, it's fairly simple to convert from Hashes to equivalent Sets
% or Dynamic Tables.
%%
% You can find more information about Hashes and how they're used on the
% <https://crcns.org/data-sets/motor-cortex/alm-3/about-alm-3 ALM-3 about page>.
loaded = load(datastructure_loc, 'obj');
data = loaded.obj;

%%
% NWB comes with default support for trial-based data.  These must be *TimeIntervals* that
% are placed in the _intervals_ property in NWB.  Note that _trials_ is a special
% keyword that is required for pyNWB compatibility.
trials = types.core.TimeIntervals(...
    'start_time', types.core.VectorData('data', data.trialStartTimes,...
    'description', 'the start time of each trial'),...
    'colnames', [data.trialTypeStr; data.trialPropertiesHash.keyNames .'],...
    'description', 'trial data and properties', ...
    'id', types.core.ElementIdentifiers('data', data.trialIds));
for i=1:length(data.trialTypeStr)
    trials.vectordata.set(data.trialTypeStr{i}, ...
        types.core.VectorData('data', data.trialTypeMat(i,:),...
            'description', data.trialTypeStr{i}));
end

for i=1:length(data.trialPropertiesHash.keyNames)
    trials.vectordata.set(data.trialPropertiesHash.keyNames{i}, ...
        types.core.VectorData(...
        'data', data.trialPropertiesHash.value{i}, ...
        'description', data.trialPropertiesHash.descr{i}));
end
nwb.intervals.set('trials', trials); %MUST be called `trials` for pynwb compatibility

ephus = data.timeSeriesArrayHash.value{1};
ephusUnit = data.timeUnitNames{data.timeUnitIds(ephus.timeUnit)};

%%
% Ephus behavioral data is stored in separate NWB locations:
%
% * Lick trace data is stored in _acquisition_ under _lick_trace_
% * AOM input trace and laser power are stored in _stimulus/presentation_ as
% _aom_input_trace_ and _laser_power_ respectively.
%
% Trial IDs, wherever they are used, will be placed in a relevent _control_ property in the
% data object and will indicate what data is associated with what trial as
% defined in the trials id column.

% lick_trace
tsIdx = strcmp(ephus.idStr, 'lick_trace');
bts = types.core.BehavioralTimeSeries();
bts.timeseries.set('lick_trace_ts', ...
    types.core.TimeSeries(...
    'control', ephus.trial, ...
    'control_description', 'trial index', ...
    'data', ephus.valueMatrix(:,tsIdx),...
    'data_unit', ephusUnit,...
    'description', ephus.idStrDetailed{tsIdx}, ...
    'timestamps', ephus.time, ...
    'timestamps_unit', ephusUnit));
nwb.acquisition.set('lick_trace', bts);

% aom
tsIdx = strcmp(ephus.idStr, 'aom_input_trace');
ts = types.core.TimeSeries(...
    'control', ephus.trial, ...
    'control_description', 'trial index', ...
    'data', ephus.valueMatrix(:,tsIdx), ...
    'data_unit', 'Volts', ...
    'description', ephus.idStrDetailed{tsIdx}, ...
    'timestamps', ephus.time, ...
    'timestamps_unit', ephusUnit);
nwb.stimulus_presentation.set('aom_input_trace', ts);
% laser_power
tsIdx = strcmp(ephus.idStr, 'laser_power');
ots = types.core.OptogeneticSeries(...
    'control', ephus.trial, ...
    'control_description', 'trial index', ...
    'data', ephus.valueMatrix(:,tsIdx), ...
    'data_unit', 'mW', ...
    'description', ephus.idStrDetailed{tsIdx}, ...
    'timestamps', ephus.time, ...
    'timestamps_unit', ephusUnit, ...
    'site', types.untyped.SoftLink('/general/optogenetics/photostim'));
nwb.stimulus_presentation.set('laser_power', ots);

%%
% Ephus spike data is separated into units which directly maps to the NWB property
% of the same name.  Each such unit contains a group of analysed waveforms and spike
% times, all linked to a different subset of trials IDs.  The waveforms are placed
% in the _analysis_ Set and are paired with their unit name ('unitx' where 'x' is
% some unit ID).  The spike times and trial IDs are kept in the *Units* object (under
% the _units_ property) along with references to the _analysis_ waveforms.
% To better how _spike_times_index_ and _spike_times_ map to each other, refer to
% <https://neurodatawithoutborders.github.io/matnwb/tutorials/html/ecephys.html#13 this
% diagram> from the Extracellular Electrophysiology Tutorial.
%%
% To index the relevent trial IDs, The _trials_ column uses *RegionView* objects.
% RegionViews are ObjectViews with extra embedded indexing information which allows
% for referring to subsets of data within a dataset.
%%
% *NOTE*: To reference indices in dynamic tables such as _intervals/trials_, the raw
% HDF5 path must point to the column (_intervals/trials/id_ in this case).
nwb.units = types.core.Units('colnames',...
    {'spike_times_index', 'spike_times', 'trials', 'waveforms'},...
    'description', 'Analysed Spike Events');
esHash = data.eventSeriesHash;
ids = regexp(esHash.keyNames, '^unit(\d+)$', 'once', 'tokens');
ids = str2double([ids{:}]);
nwb.units.id = types.core.ElementIdentifiers('data', ids);
nwb.units.spike_times_index = types.core.VectorIndex(...
    'data', types.untyped.RegionView.empty,...
    'target', types.untyped.ObjectView('/units/spike_times'));
nwb.units.spike_times = types.core.VectorData(...
    'description', 'timestamps of spikes');
trials = types.core.VectorIndex(...
    'data', types.untyped.RegionView.empty,...
    'target', types.untyped.ObjectView('/intervals/trials'));
wav_idx = types.core.VectorData('data',types.untyped.ObjectView.empty,...
    'description', 'waveform references');
trial_ids = nwb.intervals.get('trials').id.data;
for i=1:length(ids)
    esData = esHash.value{i};
    trials.data(end+1) = types.untyped.RegionView('/intervals/trials/id',...
        trial_ids == esData.eventTrials);

    nwb.units.spike_times_index.data(end+1) = ...
        types.untyped.RegionView('/units/spike_times',...
        length(nwb.units.spike_times.data) + (1:length(esData.eventTimes)));
    nwb.units.spike_times.data = [nwb.units.spike_times.data;esData.eventTimes];
    
    ses = types.core.SpikeEventSeries(...
        'control', esData.eventTrials,...
        'control_description', 'trial indices', ...
        'data', esData.waveforms, ...
        'description', esHash.descr{i}, ...
        'timestamps', esData.eventTimes, ...
        'timestamps_unit', data.timeUnitNames{data.timeUnitIds(esData.timeUnit)},...
        'electrodes', types.core.DynamicTableRegion(...
            'description', 'Electrodes involved with these spike events',...
            'table', types.untyped.ObjectView('/general/extracellular_ephys/electrodes'),...
            'data', esData.channel));
    if ~isempty(esData.cellType)
        ses.comments = ['cellType: ' esData.cellType{1}];
    end
    nwb.analysis.set(esHash.keyNames{i}, ses);
    wav_idx.data(end+1) = types.untyped.ObjectView(['/analysis/' esHash.keyNames{i}]);
end
nwb.units.vectorindex.set('trials', trials);
nwb.units.vectordata.set('waveforms', wav_idx);


%% Raw Acquisition Data
% Each ALM-3 session is associated with a large number of raw voltage data grouped by
% trial ID. To map this data to NWB, each trial is created as its own *ElectricalSeries*
% object under the name 'trial n' where 'n' is the trial ID.
untarLoc = fullfile(pwd, identifier);
if 7 ~= exist(untarLoc, 'dir')
    untar(rawdata_loc, pwd);
end

rawfiles = dir(untarLoc);
rawfiles = fullfile(untarLoc, {rawfiles(~[rawfiles.isdir]).name});

nrows = length(nwb.general_extracellular_ephys.get('electrodes').id.data);
tablereg = types.core.DynamicTableRegion(...
    'description','Relevent Electrodes for this Electrical Series',...
    'table',types.untyped.ObjectView('/general/extracellular_ephys/electrodes'),...
    'data',1:nrows);
objrefs = cell(size(rawfiles));
trials = nwb.intervals.get('trials');
endTimestamps = trials.start_time.data;
for i=1:length(rawfiles)
    tnumstr = regexp(rawfiles{i}, '_trial_(\d+)\.mat$', 'tokens', 'once');
    tnumstr = tnumstr{1};
    rawdata = load(rawfiles{i}, 'ch_MUA', 'TimeStamps');
    tnum = str2double(tnumstr);
    es = types.core.ElectricalSeries(...
        'data', rawdata.ch_MUA,...
        'description', ['Raw Voltage Acquisition for trial ' tnumstr],...
        'electrodes', tablereg,...
        'timestamps', rawdata.TimeStamps);
    tname = ['trial ' tnumstr];
    nwb.acquisition.set(tname, es);
    endTimestamps(tnum) = endTimestamps(tnum) + rawdata.TimeStamps(end);
    objrefs{tnum} = types.untyped.ObjectView(['/acquisition/' tname]);
end

%we then link to the raw data by adding the acquisition column with ObjectViews
%to the data
emptyrefs = cellfun('isempty', objrefs);
objrefs(emptyrefs) = {types.untyped.ObjectView('')};
trials.colnames{end+1} = 'acquisition';
trials.vectordata.set('acquisition', types.core.VectorData(...
    'description', 'soft link to acquisition data for this trial',...
    'data', [objrefs{:}]));
trials.stop_time = types.core.VectorData(...
    'data', endTimestamps,...
    'description', 'the end time of each trial');

rmdir(untarLoc, 's');

%% Export
% Finally, we export using the 'session_animalID' notation used in the raw data files.
outDest = fullfile(outloc, [identifier '.nwb']);
nwbExport(nwb, outDest);