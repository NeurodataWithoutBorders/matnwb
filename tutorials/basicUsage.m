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
startTimes = nwb.intervals.get('trials').start_time.data.load();
%%
% The above line on its own can be quite intimidating but should be fairly intuitive when broken down.
%%
%   nwb.intervals
%%
% This call returns a Constrained Set containing interval data, with which we retrieve the
% |trials| table using the |get()| method.  |trials| is a time interval object
% (|types.core.TimeInterval|) which is a dynamic table.  Dynamic tables (which
% inherit from |types.core.DynamicTable|) allow for an arbitrary number of columns
% which can be dynamically.  The columns are stored as individual datasets.
%%
%   start_time.data.load()
%%
% This call returns the |start time| column data.  All datasets read in by nwbRead
% are not loaded in memory by default and require an explicit call to |load()| to
% retrieve.  A |DataStub| substitutes the actual data, whose |load()| method
% will retrieve the data for you.
%
% We now read from all units and plot out all detected spikes relative to their respective start times.
% The structure of the NWB file is elaborated upon in the
% <https://neurodatawithoutborders.github.io/matnwb/tutorials/html/alm3ToNwb.html File Conversion Tutorial>.

xs = [];
ys = [];
for i=1:length(units)
    u = nwb.analysis.get(units{i});
    
    %grab unique trial IDs and mapping indices to this unit
    [tIdentifier, ~, tIndex] = unique(u.control.load());
    unit_ts = u.timestamps.load();
    % for each trial id, grab all its relative timestamps and add them as X-Axis data.
    for k=1:length(tIdentifier)
        id = tIdentifier(k);
        tLogical = tIndex == k;
        len = sum(tLogical);
        xs(end+1:end+len) = unit_ts(tLogical) - startTimes(id);
        ys(end+1:end+len) = id;
    end
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

