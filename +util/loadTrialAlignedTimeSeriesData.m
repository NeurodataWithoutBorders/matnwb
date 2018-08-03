function D = loadTrialAlignedTimeSeriesData(nwb, timeseries, window, ...
    conditions, downsample_factor, electrode)
%LOADEVENTALIGNEDTIMESERIESDATA(TIMESERIES, WINDOW, TIMES, DOWNSAMPLE_FACTOR, ELECTRODES, CONDITIONS)
%
%   NWB: matnwb NWBFile object
%   TIMESERIES: matnwb TimeSeries object
%   WINDOW: [window_start, window_end] in seconds e.g. [-.5, 1.0] gets half
%       a second before each time and 1 second after each time
%   CONDITIONS: containers.Map(condition: value)
%   DOWNSAMPLE_FACTOR: default = 1
%   ELECTRODE: detault = [] (all electrodes). Takes a 1-indexed integer,
%       (NOT AN ARRAY)
%   
%
%   OUTPUT:[]
%   array: trials x time x electrodes

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