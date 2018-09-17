%% Neurodata Without Borders: Neurophysiology, Extracellular Electrophysiology Tutorial
% This is a demonstration of how to properly write ecephys data to an NWB file using
% matnwb.

%% NWBFile
% All contents get added to the NWB file, which is created with the
% following command

date = datetime(2018, 3, 1, 12, 0, 0);
nwb = nwbfile( 'source', 'acquired on rig2', ...
    'session_description', 'a test NWB File', ...
    'identifier', 'mouse004_day4', ...
    'session_start_time', datestr(date, 'yyyy-mm-ddTHH:MM:SS'), ...
    'file_create_date', datestr(now, 'yyyy-mm-ddTHH:MM:SS'));

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


variables = {'id', 'x', 'y', 'z', 'imp', 'location', 'filtering', ...
    'description', 'group', 'group_name'};
for i_device = 1:length(udevice_labels)
    device_label = udevice_labels{i_device};
    
    nwb.general_devices.set(device_label,...
        types.core.Device('source', 'lab notebook'));
    
    nwb.general_extracellular_ephys.set(device_label,...
        types.core.ElectrodeGroup('source', 'my source', ...
        'description', 'a test ElectrodeGroup', ...
        'location', 'unknown', ...
        'device', types.untyped.SoftLink(['/general/devices/' device_label])));
    
    ov = types.untyped.ObjectView(['/general/extracellular_ephys/' device_label]);
    
    elec_nums = find(strcmp(device_labels, device_label));
    for i_elec = 1:length(elec_nums)
        elec_num = elec_nums(i_elec);
        if i_device == 1 && i_elec == 1
            tbl = table(int64(1), NaN, NaN, NaN, NaN, {'CA1'}, {'filtering'}, ...
                {'electrode label'}, ov, {'electrode_group'},...
                'VariableNames', variables);
        else
            tbl = [tbl; {int64(elec_num), NaN, NaN, NaN, NaN,...
                'CA1', 'filtering', 'another label', ov, 'electrode_group'}];
        end
    end        
end
%%
% add the ElectrodeTable object to the NWBFile using the name 'electrodes' (not flexible)
et = types.core.ElectrodeTable('data', tbl);
nwb.general_extracellular_ephys.set('electrodes', et);

%% LFP
% In order to write LFP, you need to construct a region view of the electrode 
% table to link the signal to the electrodes that generated them. You must do
% this even if the signal is from all of the electrodes. Here we will create
% a reference that includes all electrodes. Then we will randomly generate a
% signal 1000 timepoints long from 10 channels

rv = types.untyped.RegionView('/general/extracellular_ephys/electrodes',...
    {[1 height(tbl)]});

electrode_table_region = types.core.ElectrodeTableRegion('data', rv);

%%
% once you have the ElectrodeTableRegion object, you can create an
% ElectricalSeries object to hold your LFP data. Here is an example using
% starting_time and rate.

electrical_series = types.core.ElectricalSeries(...
    'source', 'my source', ...
    'starting_time', 0.0, ... % seconds
    'starting_time_rate', 200., ... % Hz
    'data',randn(1000, 10),...
    'electrodes', electrode_table_region,...
    'data_unit','V');

nwb.acquisition.set('ECoG', electrical_series);
%%
% You can also specify time using timestamps. This is particularly useful if
% the timestamps are not evenly sampled. In this case, the electrical series
% constructor will look like this

electrical_series = types.core.ElectricalSeries(...
    'timestamps', (1:1000)/200, ...
    'starting_time_rate', 200., ... % Hz
    'data', randn(1000, 10),...
    'electrodes', electrode_table_region,...
    'data_unit','V');

nwb.acquisition.set('ECoG2', electrical_series);

%% Trials
% You can store trial information in the trials table

nwb.trials = types.core.DynamicTable(...
    'colnames', {'start','stop','correct'},...
    'description', 'trial data and properties', ...
    'id', types.core.ElementIdentifiers('data', 1:3));

nwb.trials.tablecolumn.set('start', ...
    types.core.TableColumn('data', [.5, 1.5, 2.5]));

nwb.trials.tablecolumn.set('stop', ...
    types.core.TableColumn('data', [1., 2., 3.]));

nwb.trials.tablecolumn.set('correct', ...
    types.core.TableColumn('data', [0,1,0]));
%%
% `colnames` is flexible - it can store any column names and the entries can
% be any data type, which allows you to store any information you need about 
% trials. The units table stores information about cells and is created with
% an analogous workflow.

%% Writing the file
% Once you have added all of the data types you want to a file, you can save
% it with the following command

nwbExport(nwb, 'ecephys_tutorial.nwb')

%% Reading the file
% load an NWB file object into memory with

nwb2 = nwbRead('ecephys_tutorial.nwb');

%% Reading data
% Note that `nwbRead` does NOT load all of the dataset contained 
% within the file. matnwb automatically supports "lazy read" which means
% you only read data to memory when you need it, and only read the data you
% need. Notice the command

disp(nwb2.acquisition.get('ECoG').data)

%%
% does not output the values contained in `data`. To get these values, run

disp(nwb2.acquisition.get('ECoG').data.load);

%%
% Loading and displaying all of the data is not a problem for this small
% dataset, but it can be a problem when dealing with real data that can be
% several GBs or even TBs per session. You can load a specific secion of
% data. For instance, here is how you would load just a single trial


%%
% The following convenience function loads data for all trials

% data from half a second before and 1 second after start of each trial
window = [-.5, 1.]; % seconds

% only data where correct is false
conditions = containers.Map('correct',0);

timeseries = file.acquisition.get('ECoG');

utils.loadTrialAlignedTimeSeriesData(nwb2, timeseries, window, conditions)



