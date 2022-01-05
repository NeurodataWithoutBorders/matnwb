function ST = loadEventAlignedSpikeTimes(nwb,unit_id,event_times,varargin)
%LOADEVENTALIGNEDSPIKETIMES loads event-aligned spike times data for a
% single unit
%   ST = LOADEVENTALIGNEDTIMESERIESDATA(NWB, UNIT_ID, EVENT_TIMES) returns
%   a cell array containing the spike times relative to the timestamps contained
%   in the EVENT_TIMES array. Optional arguments control the size of the 
%   temporal widnow within which spike times are included.
%   OPTIONAL KEYWORD ARGUMENTS
%   'before_time' - specifies the time, in seconds, before the event for
%   the inclusion of spike times. Defaults to 1.
%   'after_time' - specifies the time, in seconds, after the event for
%   the inclusion of spike times. Defaults to 1.

% Define anonymous functions to check input
validNWB = @(x) isa(x,'types.core.NWBFile');
validUnit = @(x) isscalar(x);
validTime = @(x) isnumeric(x) && all(x>=0);
% Define parser with arguments
p = inputParser;
addRequired(p, 'nwb', validNWB);
addRequired(p, 'unit_id', validUnit);
addRequired(p, 'event_times', validTime);
addOptional(p, 'before_time', 1., validTime);
addOptional(p, 'after_time', 1., validTime);
% Parse and unpack key-value pairs
parse(p, nwb, unit_id, event_times, varargin{:});
before_time = p.Results.before_time; 
after_time = p.Results.after_time; 
% Fetch spike times for indicated unit
spike_times = nwb.units.getRow( ...
    unit_id, ...
    'columns', {'spike_times'} ...
).spike_times{1}; % need to unpack from returned MATLAB table
% Get spike times within window around indicated event timestamps
ST = cell(length(event_times),1);
for i = 1:length(event_times)
    ref_time = event_times(i);
    ST{i} = spike_times(...
                       spike_times >= ref_time - before_time & ...
                       spike_times <= ref_time + after_time) - ...
                       ref_time;
end