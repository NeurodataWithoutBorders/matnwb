function ST = loadTrialAlignedSpikeTimes(nwb,unit_id,varargin)
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
parse(p, nwb, unit_id,varargin{:});
before_time = p.Results.before_time; 
after_time = p.Results.after_time; 
align_to = p.Results.align_to;

% Get list of reference event timestamps
if strcmp(align_to, 'start_time')
    ref_event_times = nwb.intervals_trials.start_time.data.load;
elseif strcmp(align_to, 'stop_time')
    ref_event_times = nwb.intervals_trials.stop_time.data.load;
else
    ref_event_times = nwb.intervals_trials.vectordata.get(align_to).data.load;
end