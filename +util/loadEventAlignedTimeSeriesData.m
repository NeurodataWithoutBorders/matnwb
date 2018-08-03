function D = loadEventAlignedTimeSeriesData(timeseries, window, times, downsample_factor, electrodes)
%LOADEVENTALIGNEDTIMESERIESDATA(TIMESERIES, WINDOW, TIMES)
%
%   TIMESERIES: matnwb TimeSeries object
%   WINDOW: [window_start, window_end] in seconds e.g. [-.5, 1.0] gets half
%       a second before each time and 1 second after each time
%   TIMES: 1-D array of times in seconds
%   DOWNSAMPLE_FACTOR: default = 1
%   ELECTRODE: detault = [] (all electrodes). Takes a 1-indexed integer,
%       (NOT AN ARRAY)
%
%   OUTPUT:
%   array: trials x time x electrodes

if ~exist('downsample_factor','var') || isempty(downsample_factor)
    downsample_factor = 1;
end

if ~exist('electrode','var')
    electrode = [];
end

fs = timeseries.starting_time_rate;
inds_len = diff(window) * fs / downsample_factor;

dims = timeseries.data.dims;

if isempty(electrode)
    D = NaN(length(times), inds_len, dims(2));
    for i = 1:length(times)
        D(i,:,:) = util.loadTimeSeriesData(timeseries, window + times(i), ...
            downsample_factor, electrodes);
    end
else
    D = NaN(length(times), inds_len);
    for i = 1:length(times)
        D(i,:) = util.loadTimeSeriesData(timeseries, window + times(i), ...
            downsample_factor, electrodes);
    end
end
