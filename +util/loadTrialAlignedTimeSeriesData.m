function [D, tt] = loadTrialAlignedTimeSeriesData(nwb, timeseries, window, conditions, downsample_factor, electrode)
%LOADTRIALALIGNEDTIMESERIESDATA load trial-aligned time series data
%   D = LOADTRIALALIGNEDTIMESERIESDATA(NWB, TIMESERIES, WINDOW) is the
%   trial-aligned data for TIMESERIES in NWB with intervals WINDOW,
%   in seconds, for all electrodes. D is of shape trials x electrodes x time.
%
%   D = LOADTRIALALIGNEDTIMESERIESDATA(NWB, TIMESERIES, WINDOW, TIMES, DOWNSAMPLE_FACTOR)
%   specifies a temporal downsampling for D. Default is 1.
%   
%   D = LOADTRIALALIGNEDTIMESERIESDATA(NWB, TIMESERIES, WINDOW, TIMES, DOWNSAMPLE_FACTOR, ELECTRODES)
%   specifies what electrode to pull data for. Default is []:
%
%   []  - all electrodes
%   int - a single electrode (1-indexed)

if ~exist('downsample_factor', 'var') || isempty(downsample_factor)
    downsample_factor = 1;
end

if ~exist('electrode', 'var')
    electrode = [];
end

times = nwb.trials.tablecolumn.get('start').data.load;

trials_to_take = true(length(times),1);
if exist('conditions','var')
    keys = conditions.keys;
    for i = 1:length(keys)
        key = keys{i};
        val = conditions(key);
        trials_to_take = (nwb.trials.tablecolumn.get(key).data.load == val) & trials_to_take;
    end
end

times = times(trials_to_take);


D = util.loadEventAlignedTimeSeriesData(timeseries, window, times, ...
    downsample_factor, electrode);

tt = linspace(window(1), window(2), size(D,3));


