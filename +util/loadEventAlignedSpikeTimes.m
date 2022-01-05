function ST = loadEventAlignedSpikeTimes(nwb,unit_id,varargin)
%LOADEVENTALIGNEDSPIKETIMES loads event-aligned spike times data for a
% single unit
%   ST = LOADEVENTALIGNEDTIMESERIESDATA(NWB, UNIT_ID) are the
%   event-aligned spike times for all events for the indicated unit.
%   ST is cell array with length corresponding to the number of
%   events.
%   OPTIONAL KEYWORD ARGUMENTS
%   'before_time' - specifies the time, in seconds, before the event for
%   the inclusion of spike times. Defaults to 1.
%   'after_time' - specifies the time, in seconds, after the event for
%   the inclusion of spike times. Defaults to 1.
%   'align_to' - specified the column containing event timestamps to which
%   to align spike times

% Define default values
% Define anonymous functions to check input
validNWB = @(x) isa(x,'types.core.NWBFile');
validUnit = @(x) isscalar(x);
validTime = @(x) isnumeric(x) && (x>=0);
validAlign = @(x) ischar(x);
% Define parser with arguments
p = inputParser;
addRequired(p, 'nwb', validNWB);
addRequired(p, 'unit_id', validUnit);
addOptional(p, 'before_time', 1., validTime);
addOptional(p, 'after_time', 1., validTime);
addOptional(p, 'align_to', 'start_time');
% Parse and unpack key-value pairs
parse(p,nwb,unit_id,varargin{:});
before_time = p.Results.before_time; 
after_time = p.Results.after_time; 
align_to = p.Results.align_to;
% Fetch spike times for indicated unit
spike_times = nwb.units.getRow( ...
    unit_id, ...
    'columns',{'spike_times'} ...
).spike_times{1}; % need to unpack from returned MATLAB table
% Get list of reference event timestamps
if strcmp(align_to, 'start_time')
    ref_event_times = nwb.intervals_trials.start_time.data.load;
elseif strcmp(align_to, 'stop_time')
    ref_event_times = nwb.intervals_trials.stop_time.data.load;
else
    ref_event_times = nwb.intervals_trials.vectordata.get(align_to).data.load;
end
% Get spike times within window around indicated event
ST = cell(length(ref_event_times),1);
for i = 1:length(ref_event_times)
    ref_time = ref_event_times(i);
    ST{i} = spike_times(...
                       spike_times >= ref_time - before_time & ...
                       spike_times <= ref_time + after_time) - ...
                       ref_time;
end