%% Neurodata Without Borders: Neurophysiology (NWB:N), Extracellular Electrophysiology Tutorial
% How to write ecephys data to an NWB file using matnwb.
% 
%  author: Ben Dichter
%  contact: ben.dichter@gmail.com
%  last edited: Jan 22, 2019

%% NWB file
% All contents get added to the NWB file, which is created with the
% following command

date = datetime(2018, 3, 1, 12, 0, 0);
session_start_time = datetime(date, 'Format', 'yyyy-MM-dd''T''HH:mm:ssZZ',...
    'TimeZone', 'local');
nwb = nwbfile( 'source', 'acquired on rig2', ...
    'session_description', 'a test NWB File', ...
    'identifier', 'mouse004_day4', ...
    'session_start_time', session_start_time);

%%
% You can check the contents by displaying the nwbfile object
disp(nwb);

%% Data dependencies
% The data needs to be added to nwb in a specific order, which is specified
% by the data dependencies in the schema. The data dependencies for LFP are
% illustrated in the following diagram. In order to write LFP, you need to 
% specify what electrodes it came from. To do that, you first need to 
% construct an electrode table. 
%%
% 
% <<ecephys_data_deps.png>>
% 

%% Electrode Table
% Electrode tables hold the position and group information about each 
% electrode and the brain region and filtering. Groups organize electrodes 
% within a single device. Devices can have 1 or more groups. In this example, 
% we have 2 devices that each only have a single group.

device_labels = {'a','a','a','a','a','b','b','b','b','b'};

udevice_labels = unique(device_labels, 'stable');

variables = {'x', 'y', 'z', 'imp', 'location', 'filtering', ...
    'group', 'label'};
for i_device = 1:length(udevice_labels)
    device_label = udevice_labels{i_device};
    
    nwb.general_devices.set(device_label,...
        types.core.Device());
    
    nwb.general_extracellular_ephys.set(device_label,...
        types.core.ElectrodeGroup(...
        'description', 'a test ElectrodeGroup', ...
        'location', 'unknown', ...
        'device', types.untyped.SoftLink(['/general/devices/' device_label])));
    
    ov = types.untyped.ObjectView(['/general/extracellular_ephys/' device_label]);
    
    elec_nums = find(strcmp(device_labels, device_label));
    for i_elec = 1:length(elec_nums)
        elec_num = elec_nums(i_elec);
        if i_device == 1 && i_elec == 1
            tbl = table(NaN, NaN, NaN, NaN, {'CA1'}, {'filtering'}, ...
                ov, {'electrode_label'},'VariableNames', variables);
        else
            tbl = [tbl; {NaN, NaN, NaN, NaN,...
                'CA1', 'filtering', ov, 'electrode_label'}];
        end
    end        
end
%%
% add the |DynamicTable| object to the NWB file in
% /general/extracellular_ephys/electrodes

electrode_table = util.table2nwb(tbl, 'all electrodes');
nwb.general_extracellular_ephys_electrodes = electrode_table;

%% Multielectrode recording
% In order to write a multielectrode recording, you need to construct a 
% region view of the electrode table to link the signal to the electrodes 
% that generated them. You must do this even if the signal is from all of 
% the electrodes. Here we will create a reference that includes all 
% electrodes. Then we will generate a signal 1000 timepoints long from 10 
% channels.

ov = types.untyped.ObjectView('/general/extracellular_ephys/electrodes');

electrode_table_region = types.core.DynamicTableRegion('table', ov, ...
    'description', 'all electrodes',...
    'data', [0 height(tbl)-1]');

%%
% once you have the |ElectrodeTableRegion| object, you can create an
% |ElectricalSeries| object to hold your multielectrode data. An 
% |ElectricalSeries| is an example of a |TimeSeries| object. For all 
% |TimeSeries| objects, you have 2 options for storing time information.
% The first is to use |starting_time| and |rate|:

% generate data for demonstration
data = reshape(1:10000, 10, 1000);

electrical_series = types.core.ElectricalSeries(...
    'starting_time', 0.0, ... % seconds
    'starting_time_rate', 200., ... % Hz
    'data', data,...
    'electrodes', electrode_table_region,...
    'data_unit','V');

nwb.acquisition.set('ECoG', electrical_series);
%%
% You can also specify time using |timestamps|. This is particularly useful if
% the sample times are not evenly sampled. In this case, the electrical series
% constructor will look like this

electrical_series = types.core.ElectricalSeries(...
    'timestamps', (1:1000)/200, ...
    'data', data,...
    'electrodes', electrode_table_region,...
    'data_unit','V');

%% Trials
% You can store trial information in the trials table

trials = types.core.TimeIntervals( ...
    'colnames', {'correct','start_time','stop_time'},...
    'description', 'trial data and properties', ...
    'id', types.core.ElementIdentifiers('data', 0:2),...
    'start_time', types.core.VectorData('data', [.1, 1.5, 2.5],...
        'description','start time of trial'),...
    'stop_time', types.core.VectorData('data', [1., 2., 3.],...
        'description','end of each trial'),...
    'correct', types.core.VectorData('data', [false,true,false],...
        'description','my description'));

nwb.intervals_trials = trials;

%%
% |colnames| is flexible - it can store any column names and the entries can
% be any data type, which allows you to store any information you need about 
% trials.

%% Spikes
% Spikes are stored in the |units| table, which uses 3 arrays to store the
% spike times of all the cells.

%%
% 
% <<UnitTimes.png>>
% 
%%
% The |units| table is a |DynamicTable| meaning it has some key terms that
% are optional: electrode_group, electrodes,
% obs_intervals, spike_times, waveform_mean, waveform_sd.
% If there is a value you would like to store that is not
% in this list, you can add it yourself (demonstrated with "quality")

spike_times = [0.1, 0.21, 0.34, 0.36, 0.4, 0.43, 0.5, 0.61, 0.66, 0.69];
unit_ids = [0, 0, 1, 1, 2, 2, 0, 0, 1, 1];
[spike_times_vector, spike_times_index] = util.create_spike_times(unit_ids, spike_times);

waveform_mean = types.core.VectorData('data', ones(30, 3),...
    'description', 'mean of waveform');

quality = types.core.VectorData('data', [.9, .1, .2],...
    'description', 'sorting quality score out of 1');

nwb.units = types.core.Units('colnames', {'spike_times', 'waveform_mean', 'quality'}, ...
    'description', 'units table', ...
    'id', types.core.ElementIdentifiers('data', 0:length(spike_times_index.data) - 1));
nwb.units.spike_times = spike_times_vector;
nwb.units.spike_times_index = spike_times_index;
nwb.units.waveform_mean = waveform_mean;
nwb.units.vectordata.set('quality', quality);

%% Processing Modules
% Measurements go in |acquisition| and subject or session data goes in
% |general|, but if you have the intermediate processing results, you
% should put them in a processing module.

ecephys_mod = types.core.ProcessingModule('description', 'contains clustering data');

%%
% The |Clustering| data structure holds information about the spike-sorting
% process.

clustering = types.core.Clustering( ...
    'description', 'my_description', ...
    'peak_over_rms', [1, 2, 3], ...
    'times', spike_times, ...
    'num', cluster_ids);

cell_mod.nwbdatainterface.set('clustering', clustering);

%%
% I am going to call this processing module "ecephys." As a convention, I 
% use the names of the NWB core namespace modules as the names of my 
% processing modules, however this is not a rule and you may use any name.

nwb.processing.set('ecephys', ecephys_mod);

%% Writing the file
% Once you have added all of the data types you want to a file, you can save
% it with the following command

nwbExport(nwb, 'ecephys_tutorial.nwb')

%% Reading the file
% load an NWB file object with

nwb2 = nwbRead('ecephys_tutorial.nwb');

%% Reading data
% Note that |nwbRead| does *not* load all of the dataset contained 
% within the file. matnwb automatically supports "lazy read" which means
% you only read data to memory when you need it, and only read the data you
% need. Notice the command

disp(nwb2.acquisition.get('ECoG').data)

%%
% returns a DataStub object and does not output the values contained in 
% |data|. To get these values, run

data = nwb2.acquisition.get('ECoG').data.load;
disp(data(1:10, 1:10));

%%
% Loading all of the data can be a problem when dealing with real data that can be
% several GBs or even TBs per session. In these cases you can load a specific section of
% data. For instance, here is how you would load data starting at the index
% (1,1) and read 10 rows and 20 columns of data

nwb2.acquisition.get('ECoG').data.load([1,1], [10,20])

%%
% run |doc('types.untyped.DataStub')| for more details on manual partial
% loading. There are several convenience functions that make common data
% loading patterns easier. The following convenience function loads data 
% for all trials

% data from .05 seconds before and half a second after start of each trial
window = [-.05, 0.5]; % seconds

% only data where the attribute 'correct' == 0
conditions = containers.Map('correct', 0);

% get ECoG data
timeseries = nwb2.acquisition.get('ECoG');

[trial_data, tt] = util.loadTrialAlignedTimeSeriesData(nwb2, ...
    timeseries, window, conditions);

% plot data from the first electrode for those two trials
plot(tt, squeeze(trial_data(:,1,:)))
xlabel('time (seconds)')
ylabel(['ECoG (' timeseries.data_unit ')'])

%% Reading units (RegionViews)
% The |units| table uses an index array to indicate which spikes belong to which cell.
% The structure is split up into 3 datasets (see Spikes secion):
my_spike_times = nwb.units.spike_times;
%%
% To get the data for cell 1, first determine the uid that equals 1.
upper_bound_ind = find(nwb.units.id.data == 1);

upper_bound = nwb.units.spike_times_index.data(upper_bound_ind);
if upper_bound_ind == 1
    lower_bound = 1;
else
    lower_bound = nwb.units.spike_times_index.data(upper_bound_ind-1);
end
%%
% Then select the corresponding spike_times_index element
data = nwb.units.spike_times.data(lower_bound + 1:upper_bound);


%% External Links
% NWB allows you to link to datasets within another file through HDF5
% |ExternalLink|s. This is useful for separating out large datasets that are
% not always needed. It also allows you to store data once, and access it 
% across many NWB files, so it is useful for storing subject-related
% data that is the same for all sessions. Here is an example of creating a
% link from the Subject object from the |ecephys_tutorial.nwb| file we just
% created in a new file.
 
nwb3 = nwbfile('session_description', 'a test NWB File', ...
    'identifier', 'mouse004_day4', ...
    'session_start_time', session_start_time);
nwb3.general_subject = types.untyped.ExternalLink('ecephys_tutorial.nwb',...
    '/general/subject');
 
nwbExport(nwb3, 'link_test.nwb')
