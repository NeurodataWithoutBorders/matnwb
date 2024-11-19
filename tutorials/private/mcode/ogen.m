%% Optogenetics
% This tutorial will demonstrate how to write optogenetics data.
%% Creating an NWBFile object
% When creating a NWB file, the first step is to create the |*NWBFile*| object 
% using <https://neurodatawithoutborders.github.io/matnwb/doc/NwbFile.html |*NwbFile*|>.

nwb = NwbFile( ...
    'session_description', 'mouse in open exploration',...
    'identifier', char(java.util.UUID.randomUUID), ...
    'session_start_time', datetime(2018, 4, 25, 2, 30, 3, 'TimeZone', 'local'), ...
    'general_experimenter', 'Last, First M.', ... % optional
    'general_session_id', 'session_1234', ... % optional
    'general_institution', 'University of My Institution', ... % optional
    'general_related_publications', 'DOI:10.1016/j.neuron.2016.12.011'); % optional
nwb
%% Adding optogenetic data<http://localhost:63342/pynwb/docs/_build/html/tutorials/domain/ogen.html#adding-optogenetic-data ¶>
% The |*ogen*| module contains two data types that you will need to write optogenetics 
% data, <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/OptogeneticStimulusSite.html 
% |*OptogeneticStimulusSite*|>, which contains metadata about the stimulus site, 
% and <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/OptogeneticSeries.html 
% |*OptogeneticSeries*|>, which contains the values of the time series.
% 
% First, you need to create a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Device.html 
% |*Device*|> object linked to the |*NWBFile*|:

device = types.core.Device();
nwb.general_devices.set('Device', device);
%% 
% Now, you can create and add an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/OptogeneticStimulusSite.html 
% |*OptogeneticStimulusSite*|>. 

ogen_stim_site = types.core.OptogeneticStimulusSite( ...
    'device', types.untyped.SoftLink(device), ...
    'description', 'This is an example optogenetic site.', ...
    'excitation_lambda', 600.0, ...
    'location', 'VISrl');

nwb.general_optogenetics.set('OptogeneticStimulusSite', ogen_stim_site);
%% 
% With the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/OptogeneticStimulusSite.html 
% |*OptogeneticStimulusSite*|> added, you can now create and add a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/OptogeneticSeries.html 
% |*OptogeneticSeries*|>. Here, we will generate some random data and specify 
% the timing using |rate|. If you have samples at irregular intervals, you should 
% use |timestamps| instead.

ogen_series = types.core.OptogeneticSeries( ...
    'data', randn(20, 1), ...
    'site', types.untyped.SoftLink(ogen_stim_site), ...
    'starting_time', 0.0, ...
    'starting_time_rate', 30.0);  % Hz
nwb.stimulus_presentation.set('OptogeneticSeries', ogen_series);

nwb
%% 
% Now you can write the NWB file.

nwbExport(nwb, 'ogen_tutorial.nwb');