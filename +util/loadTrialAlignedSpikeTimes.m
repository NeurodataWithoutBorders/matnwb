function ST = loadTrialAlignedSpikeTimes(nwb,unit_id,varargin)
% Define anonymous functions to check input
validNWB = @(x) isa(x,'types.core.NWBFile');
validUnit = @(x) isscalar(x);
validTime = @(x) isnumeric(x) && (x>=0);
validAlign = @(x) ischar(x);
validCond = @(x) isa(x,'containers.Map');
% Define parser with arguments
p = inputParser;
addRequired(p, 'nwb', validNWB);
addRequired(p, 'unit_id', validUnit);
addOptional(p, 'before_time', 1., validTime);
addOptional(p, 'after_time', 1., validTime);
addOptional(p, 'align_to', 'start_time', validAlign);
addOptional(p, 'conditions', containers.Map(), validCond);
% Parse and unpack key-value pairs
parse(p, nwb, unit_id,varargin{:});
align_to = p.Results.align_to;
conditions = p.Results.conditions;
% Get list of reference event timestamps
if strcmp(align_to, 'start_time')
    ref_event_times = nwb.intervals_trials.start_time.data.load;
elseif strcmp(align_to, 'stop_time')
    ref_event_times = nwb.intervals_trials.stop_time.data.load;
else
    ref_event_times = nwb.intervals_trials.vectordata.get(align_to).data.load;
end
% Select subset of trials based on conditions
trials_to_take = true(length(ref_event_times),1);
trials = nwb.intervals_trials;
keys = conditions.keys;
for i = 1:length(keys)
    key = keys{i};
    val = conditions(key);
    if strcmp(key, 'start_time')
        col = trials.start_time;
    elseif strcmp(key, 'stop_time')
        col = trials.stop_time;
    else
        col = trials.vectordata.get(key);
    end

    if isa(val, 'function_handle')
        trials_to_take = val(col.data.load) & trials_to_take;
    else
        trials_to_take = (col.data.load == val) & trials_to_take;
    end
end

ref_event_times = ref_event_times(trials_to_take);
% call event utility function
ST = util.loadEventAlignedSpikeTimes(nwb, unit_id, ref_event_times, ...
    'before_time', p.Results.before_time, ...
    'after_time', p.Results.after_time ...
);