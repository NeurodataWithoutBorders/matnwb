%% Neurodata Without Borders Extracellular Electrophysiology Tutorial
%% This tutorial
% Create fake data for a hypothetical extracellular electrophysiology experiment. 
% The types of data we will convert are:
%% 
% * Voltage recording
% * Local field potential (LFP)
% * Spike times
%% 
% It is recommended to first work through the <https://neurodatawithoutborders.github.io/matnwb/tutorials/html/intro.html 
% Introduction to MatNWB tutorial>, which demonstrates installing MatNWB and creating 
% an NWB file with subject information, animal position, and trials, as well as 
% writing and reading NWB files in MATLAB.
%% Setting up the NWB File
% An NWB file represents a single session of an experiment. Each file must have 
% a session_description, identifier, and session start time. Create a new <https://neurodatawithoutborders.github.io/matnwb/doc/NwbFile.html 
% |*NWBFile*|> object with those and additional metadata. For all MatNWB functions, 
% we use the Matlab method of entering keyword argument pairs, where arguments 
% are entered as name followed by value.

nwb = NwbFile( ...
    'session_description', 'mouse in open exploration',...
    'identifier', 'Mouse5_Day3', ...
    'session_start_time', datetime(2018, 4, 25, 2, 30, 3, 'TimeZone', 'local'), ...
    'timestamps_reference_time', datetime(2018, 4, 25, 3, 0, 45, 'TimeZone', 'local'), ...
    'general_experimenter', 'Last Name, First Name', ... % optional
    'general_session_id', 'session_1234', ... % optional
    'general_institution', 'University of My Institution', ... % optional
    'general_related_publications', {'DOI:10.1016/j.neuron.2016.12.011'}); % optional
nwb
%% Extracellular Electrophysiology
% In order to store extracellular electrophysiology data, you first must create 
% an electrodes table describing the electrodes that generated this data. Extracellular 
% electrodes are stored in an |electrodes| table, which is also a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+hdmf_common/DynamicTable.html 
% |*DynamicTable*|>. |electrodes| has several required fields: |x|, |y|, |z|, 
% |impedance|, |location|, |filtering|, and |electrode_group|.
%% Electrodes Table
% 
% 
% Since this is a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+hdmf_common/DynamicTable.html 
% |*DynamicTable*|>, we can add additional metadata fields. We will be adding 
% a "label" column to the table.

numShanks = 4;
numChannelsPerShank = 3;

ElectrodesDynamicTable = types.hdmf_common.DynamicTable(...
    'colnames', {'location', 'group', 'group_name', 'label'}, ...
    'description', 'all electrodes');

Device = types.core.Device(...
    'description', 'the best array', ...
    'manufacturer', 'Probe Company 9000' ...
);
nwb.general_devices.set('array', Device);
for iShank = 1:numShanks
    shankGroupName = sprintf('shank%d', iShank);
    EGroup = types.core.ElectrodeGroup( ...
        'description', sprintf('electrode group for %s', shankGroupName), ...
        'location', 'brain area', ...
        'device', types.untyped.SoftLink(Device) ...
    );
    
    nwb.general_extracellular_ephys.set(shankGroupName, EGroup);
    for iElectrode = 1:numChannelsPerShank
        ElectrodesDynamicTable.addRow( ...
            'location', 'unknown', ...
            'group', types.untyped.ObjectView(EGroup), ...
            'group_name', shankGroupName, ...
            'label', sprintf('%s-electrode%d', shankGroupName, iElectrode));
    end
end
ElectrodesDynamicTable.toTable() % Display the table

nwb.general_extracellular_ephys_electrodes = ElectrodesDynamicTable;
%% Links
% In the above loop, we create <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ElectrodeGroup.html 
% |*ElectrodeGroup*|> objects. The |electrodes| table then uses an |ObjectView| 
% in each row to link to the corresponding <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ElectrodeGroup.html 
% |*ElectrodeGroup*|> object. An |ObjectView| is an object that allow you to create 
% a link from one neurodata type referencing another. 
%% ElectricalSeries
% Voltage data are stored in <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ElectricalSeries.html 
% |*ElectricalSeries*|> objects. <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ElectricalSeries.html 
% |*ElectricalSeries*|> is a subclass of <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeSeries.html 
% |*TimeSeries*|> specialized for voltage data. In order to create our <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ElectricalSeries.html 
% |*ElectricalSeries*|> object, we will need to reference a set of rows in the 
% |electrodes| table to indicate which electrodes were recorded. We will do this 
% by creating a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+hdmf_common/DynamicTableRegion.html 
% |*DynamicTableRegion*|>, which is a type of link that allows you to reference 
% specific rows of a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+hdmf_common/DynamicTable.html 
% |*DynamicTable*|>, such as the |electrodes| table, by row indices.
% 
% Create a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+hdmf_common/DynamicTableRegion.html 
% |*DynamicTableRegion*|> that references all rows of the |electrodes| table.

electrode_table_region = types.hdmf_common.DynamicTableRegion( ...
    'table', types.untyped.ObjectView(ElectrodesDynamicTable), ...
    'description', 'all electrodes', ...
    'data', (0:length(ElectrodesDynamicTable.id.data)-1)');
%% 
% Now create an |ElectricalSeries| object to hold acquisition data collected 
% during the experiment.
% 
% 

electrical_series = types.core.ElectricalSeries( ...
    'starting_time', 0.0, ... % seconds
    'starting_time_rate', 30000., ... % Hz
    'data', randn(12, 3000), ...
    'electrodes', electrode_table_region, ...
    'data_unit', 'volts');
%% 
% This is the voltage data recorded directly from our electrodes, so it goes 
% in the acquisition group. 

nwb.acquisition.set('ElectricalSeries', electrical_series);
%% LFP
% Local field potential (LFP) refers in this case to data that has been downsampled 
% and/or filtered from the original acquisition data and is used to analyze signals 
% in the lower frequency range. Filtered and downsampled LFP data would also be 
% stored in an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ElectricalSeries.html 
% |*ElectricalSeries*|>. To help data analysis and visualization tools know that 
% this <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ElectricalSeries.html 
% |*ElectricalSeries*|> object represents LFP data, store it inside an |LFP| object, 
% then place the |LFP| object in a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ProcessingModule.html 
% |*ProcessingModule*|> named |'ecephys'|. This is analogous to how we stored 
% the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpatialSeries.html 
% |*SpatialSeries*|> object inside of a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Position.html 
% |*Position*|> object and stored the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Position.html 
% |*Position*|> object in a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ProcessingModule.html 
% |*ProcessingModule*|> named |'behavior'| earlier.
% 
% 

lfp_electrical_series = types.core.ElectricalSeries( ...
    'starting_time', 0.0, ... % seconds
    'starting_time_rate', 1000., ... % Hz
    'data', randn(12, 100), ...
    'electrodes', electrode_table_region, ...
    'data_unit', 'volts');

lfp = types.core.LFP('ElectricalSeries', lfp_electrical_series);

ecephys_module = types.core.ProcessingModule(...
    'description', 'extracellular electrophysiology');

ecephys_module.nwbdatainterface.set('LFP', lfp);
nwb.processing.set('ecephys', ecephys_module);
% Decomposition of LFP Data into Frequency Bands
% In some cases, you may want to further process the LFP data and decompose 
% the signal into different frequency bands for additional downstream analyses. 
% You can store the processed data from these spectral analyses using a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/DecompositionSeries.html 
% |*DecompositionSeries*|> object. This object allows you to include metadata 
% about the frequency bands and metric used (e.g., |power|, |phase|, |amplitude|), 
% as well as link the decomposed data to the original <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeSeries.html 
% |*TimeSeries*|> signal the data was derived from.
% 
% *Note*: When adding data to a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/DecompositionSeries.html 
% |*DecompositionSeries*|>, the |data| argument is assumed to be 3D where the 
% first dimension is time, the second dimension is channels, and the third dimension 
% is bands. In MatNWB, the data needs to be permuted because the dimensions are 
% written to file in reverse order (See the <./dimensionMapNoDataPipes.mlx dimensionMapNoDataPipes> 
% tutorial)

% Define the frequency bands of interest (in Hz):
band_names = {'theta'; 'beta'; 'gamma'};
band_mean = [8; 21; 55];
band_stdev = [2; 4.5; 12.5];
band_limits = [band_mean - 2*band_stdev, band_mean + 2*band_stdev];

% The bands should be added to the DecompositionSeries as a dynamic table
bands = table(band_names, band_mean, band_stdev, band_limits, ...
    'VariableNames', {'band_names', 'band_mean', 'band_stdev', 'band_limits'})

bands = util.table2nwb( bands );

% Generate random phase data for the demonstration.
phase_data = randn(50, 12, numel(band_names)); % 50 samples, 12 channels, 3 frequency bands
phase_data = permute(phase_data, [3,2,1]); % See dimensionMapNoDataPipes tutorial

decomp_series = types.core.DecompositionSeries(...
    'data', phase_data, ...
    'bands', bands, ...
    'metric', 'phase', ...
    'starting_time', 0.0, ... % seconds
    'starting_time_rate', 1000.0, ... % Hz
    'source_channels', electrode_table_region, ...
    'source_timeseries', lfp_electrical_series);

% Add decomposition series to ecephys module
ecephys_module.nwbdatainterface.set('theta', decomp_series);
%% Sorted Spike Times
% Ragged Arrays
% Spike times are stored in another <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+hdmf_common/DynamicTable.html 
% |*DynamicTable*|> of subtype <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Units.html 
% |*Units*|>. The default |Units| table is at |/units| in the HDF5 file. You can 
% add columns to the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Units.html 
% |*Units*|> table just like you did for |electrodes| and |trials|. Here, we generate 
% some random spike data and populate the table. 

num_cells = 10;
firing_rate = 20;
spikes = cell(1, num_cells);
for iShank = 1:num_cells
    spikes{iShank} = rand(1, randi([16, 28]));
end
spikes
%% 
% Spike times are an example of a ragged array- it's like a matrix, but each 
% row has a different number of elements. We can represent this type of data as 
% an indexed column of the units <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+hdmf_common/DynamicTable.html 
% |*DynamicTable*|>. These indexed columns have two components, the vector data 
% object that holds the data and the vector index object that holds the indices 
% in the vector that indicate the row breaks. You can use the convenience function 
% |util.create_indexed_column| to create these objects.
% 
% 

[spike_times_vector, spike_times_index] = util.create_indexed_column(spikes);

nwb.units = types.core.Units( ...
    'colnames', {'spike_times'}, ...
    'description', 'units table', ...
    'spike_times', spike_times_vector, ...
    'spike_times_index', spike_times_index ...
);

nwb.units.toTable
%% Unsorted Spike Times
% In MATLAB, while the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Units.html 
% |*Units*|> table is used to store spike times and waveform data for spike-sorted, 
% single-unit activity, you may also want to store spike times and waveform snippets 
% of unsorted spiking activity. This is useful for recording multi-unit activity 
% detected via threshold crossings during data acquisition. Such information can 
% be stored using <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpikeEventSeries.html 
% |*SpikeEventSeries*|> objects.

% In the SpikeEventSeries the dimensions should be ordered as 
% [num_events, num_channels, num_samples].
% Define spike snippets: 20 events, 3 channels, 40 samples per event. 
spike_snippets = rand(20, 3, 40);
% Permute spike snippets (See dimensionMapNoDataPipes tutorial)
spike_snippets = permute(spike_snippets, [3,2,1]) 

% Create electrode table region referencing electrodes 0, 1, and 2
shank0_table_region = types.hdmf_common.DynamicTableRegion( ...
    'table', types.untyped.ObjectView(ElectrodesDynamicTable), ...
    'description', 'shank0', ...
    'data', (0:2)');

% Define spike event series for unsorted spike times
spike_events = types.core.SpikeEventSeries( ...
    'data', spike_snippets, ...
    'timestamps', (0:19)', ...  % Timestamps for each event
    'description', 'events detected with 100uV threshold', ...
    'electrodes', shank0_table_region ...
);

% Add spike event series to NWB file acquisition
nwb.acquisition.set('SpikeEvents_Shank0', spike_events);
%% Designating Electrophysiology Data
% As mentioned above, <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ElectricalSeries.html 
% |*ElectricalSeries*|> objects are meant for storing specific types of extracellular 
% recordings. In addition to this <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeSeries.html 
% |*TimeSeries*|> class, NWB provides some <https://pynwb.readthedocs.io/en/stable/tutorials/general/plot_file.html#modules-overview 
% Processing Modules> for designating the type of data you are storing. We will 
% briefly discuss them here, and refer the reader to the <https://neurodatawithoutborders.github.io/matnwb/doc/index.html 
% *API documentation*> and <https://neurodatawithoutborders.github.io/matnwb/tutorials/html/intro.html 
% *Intro to NWB*> for more details on using these objects.
% 
% For storing unsorted spiking data, there are two options. Which one you choose 
% depends on what data you have available. If you need to store complete and/or 
% continuous raw voltage traces, you should store the traces with <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ElectricalSeries.html 
% |*ElectricalSeries*|> objects as acquisition data, and use the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/EventDetection.html 
% |*EventDetection*|> class for identifying the spike events in your raw traces. 
% If you do not want to store the raw voltage traces and only the waveform ‘snippets’ 
% surrounding spike events, you should use <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpikeEventSeries.html 
% |*SpikeEventSeries*|> objects.
% 
% The results of spike sorting (or clustering) should be stored in the top-level 
% <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Units.html 
% |*Units*|> table. The <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Units.html 
% |*Units*|> table can hold just the spike times of sorted units or, optionally, 
% include additional waveform information. You can use the optional predefined 
% columns |waveform_mean|, |waveform_sd|, and |waveforms| in the  <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Units.html 
% |*Units*|> table to store individual and mean waveform data.
% 
% For local field potential data, there are two options. Again, which one you 
% choose depends on what data you have available. With both options, you should 
% store your traces with <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ElectricalSeries.html 
% |*ElectricalSeries*|> objects. If you are storing unfiltered local field potential 
% data, you should store the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ElectricalSeries.html 
% |*ElectricalSeries*|> objects in <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/LFP.html 
% |*LFP*|> data interface object(s). If you have filtered LFP data, you should 
% store the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ElectricalSeries.html 
% |*ElectricalSeries*|> objects in <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/FilteredEphys.html 
% |*FilteredEphys*|> data interface object(s).
%% Writing the NWB File

nwbExport(nwb, 'ecephys_tutorial.nwb')
%% Reading NWB Data
% Data arrays are read passively from the file. Calling |TimeSeries.data| does 
% not read the data values, but presents an HDF5 object that can be indexed to 
% read data. This allows you to conveniently work with datasets that are too large 
% to fit in RAM all at once. |load| with no input arguments reads the entire dataset:

nwb2 = nwbRead('ecephys_tutorial.nwb', 'ignorecache');
nwb2.processing.get('ecephys'). ...
    nwbdatainterface.get('LFP'). ...
    electricalseries.get('ElectricalSeries'). ...
    data.load;
%% Accessing Data Regions
% If all you need is a data region, you can index a |DataStub| object like you 
% would any normal array in MATLAB, as shown below. When indexing the dataset 
% this way, only the selected region is read from disk into RAM. This allows you 
% to handle very large datasets that would not fit entirely into RAM.

% read section of LFP
nwb2.processing.get('ecephys'). ...
    nwbdatainterface.get('LFP'). ...
    electricalseries.get('ElectricalSeries'). ...
    data(1:5, 1:10)

% You can use the getRow method of the table to load spike times of a specific unit.
% To get the values, unpack from the returned table.
nwb.units.getRow(1).spike_times{1}
%% Learn more!
% See the <https://neurodatawithoutborders.github.io/matnwb/doc/index.html API documentation> to learn what data types are available.
%% MATLAB tutorials
%% 
% * <https://neurodatawithoutborders.github.io/matnwb/tutorials/html/ophys.html 
% Optical physiology>
% * <https://neurodatawithoutborders.github.io/matnwb/tutorials/html/icephys.html 
% Intracellular electrophysiology>
%% Python tutorials
% See our tutorials for more details about your data type:
%% 
% * <https://pynwb.readthedocs.io/en/stable/tutorials/domain/ophys.html#sphx-glr-tutorials-domain-ophys-py 
% Calcium imaging>
% * <https://pynwb.readthedocs.io/en/stable/tutorials/domain/ecephys.html#sphx-glr-tutorials-domain-ecephys-py 
% Extracellular electrophysiology>
% * <https://pynwb.readthedocs.io/en/stable/tutorials/domain/icephys.html#sphx-glr-tutorials-domain-icephys-py 
% Intracellular electrophysiology>
%% 
% *Check out other tutorials that teach advanced NWB topics:*
%% 
% * <https://pynwb.readthedocs.io/en/stable/tutorials/general/iterative_write.html#sphx-glr-tutorials-general-iterative-write-py 
% Iterative data write>
% * <https://pynwb.readthedocs.io/en/stable/tutorials/general/extensions.html#sphx-glr-tutorials-general-extensions-py 
% Extensions>
% * <https://pynwb.readthedocs.io/en/stable/tutorials/general/advanced_hdf5_io.html#sphx-glr-tutorials-general-advanced-hdf5-io-py 
% Advanced HDF5 I/O>
%%