%% Using NWB Data
% How to interface with Neurodata Without Borders files using MatNWB.
% In this tutorial, we create a raster map of spikes extracted for the dataset
% extracted from the
% <https://neurodatawithoutborders.github.io/matnwb/tutorials/html/convertTrials.html File Conversion Tutorial>.
% Reading the conversion tutorial is unnecessary for this tutorial if one only requires
% accessing the data.
%
%  author: Lawrence Niu
%  contact: lawrence@vidriotech.com
%  last updated: Jan 01, 2019
%
%% Reading NWB Files
% NWB files can be read using the |nwbRead()| function.
% This function returns a |nwbfile| object which represents the nwb file structure.
%
nwb = nwbRead('out\ANM255200_20140910.nwb');
%% Constrained Sets
% Analyzed data in NWB is placed under the |analysis| property, which is a *Constrained Set*.
% A constrained set consists of an arbitrary amount of key-value pairs similar to a Map.
% The difference between constrained sets are due to their capability to validate their
% own properties.
%%
% You can get/set values in constrained sets using the methods |.get()| and |.set()|
% respectively, and retrieve all Set properties using the |keys()| method;
units = keys(nwb.analysis);
%% Accessing Data
startTimes = nwb.intervals_trials.start_time.data.load();
%%
% The above line on its own can be quite intimidating but should be fairly intuitive when broken down.
%%
%   nwb.intervals_trials
%%
% This call returns a |trials| table.  |trials| is a time interval object
% (|types.core.TimeInterval|) which is a dynamic table.  Dynamic tables (which
% inherit from |types.core.DynamicTable|) allow for an arbitrary number of columns
% which can be dynamically modified.  The columns are stored as individual datasets.
%%
%   start_time.data.load()
%%
% This call returns the |start time| column data.  All datasets read in by nwbRead
% are not loaded in memory by default and require an explicit call to |load()| to
% retrieve.  A |DataStub| substitutes the actual data, whose |load()| method
% will retrieve the data for you.
%
% We now read from all units and plot out all detected spikes relative to their respective start times.
% The structure of the NWB file and references for more advanced details like vector
% indices and vector data can be found in the
% <https://neurodatawithoutborders.github.io/matnwb/tutorials/html/convertTrials.html Conversion From Trial Data> Tutorial.

unit_trial = nwb.units.vectordata.get('trials');
unit_trial_idx = nwb.units.vectorindex.get('trials_index').data.load();
unit_times = nwb.units.spike_times;
unit_times_idx = nwb.units.spike_times_index.data.load();
xs = [];
ys = [];
for i=1:length(units)
    u = nwb.analysis.get(units{i});
    id = u.control.load();
    
    if id == 1
        trial_start_i = 1;
        times_start_i = 1;
    else
        trial_start_i = unit_trial_idx(id-1) + 1;
        times_start_i = unit_times_idx(id-1) + 1;
    end
    trial_end_i = unit_trial_idx(id);
    times_end_i = unit_times_idx(id);
    
    trials = unit_trial.data.load(trial_start_i, trial_end_i);
    times = unit_times.data.load(times_start_i, times_end_i);
    len = length(trials);
    xs(end+1:end+len) = times - startTimes(trials);
    ys(end+1:end+len) = trials;    
end

hScatter = scatter(xs, ys, 'Marker', '.', 'MarkerFaceColor', 'flat',...
    'CData', [0 0 0], 'SizeData', 1);

hAxes = hScatter.Parent;
hAxes.YLabel.String = 'Trial number';
hAxes.XLabel.String = 'Time (sec)';
hAxes.XTick = 0:max(xs);
hAxes.YTick = 0:50:max(ys);
hAxes.Parent.Position(4) = hAxes.Parent.Position(4) * 2;
snapnow;

