function data = loadTimeSeriesData(timeseries, interval, downsample_factor, electrode)
%LOADTIMESERIESDATA loads data within a time interval from a timeseries
%
%   DATA = loadTimeSeriesData(TIMESERIES, INTERVAL, DOWNSAMPLE_FACTOR)
%   TIMESERIES: matnwb TimeSeries object
%   INTERVAL: [start end] in seconds
%   DOWNSAMPLE_FACTOR: default = 1
%   ELECTRODE: detault = [] (all electrodes). Takes a 1-indexed integer,
%   (NOT AN ARRAY)
%   Works whether timestamps or starting_time & rate are stored. Assumes
%   timestamps are sorted in ascending order.

if ~exist('interval','var')
    interval = [0 Inf];
end

if ~exist('downsample_factor','var') || isempty(downsample_factor)
    downsample_factor = 1;
end

if ~exist('electrode','var')
    electrode = [];
end

dims = timeseries.data.dims;

if interval(1)
    if isempty(timeseries.starting_time)
        start_ind = fastsearch(timeseries.timestamps, interval(1), 1);
    else
        fs = timeseries.starting_time_rate;
        t0 = timeseries.starting_time;
        if interval(1) < t0
            error('interval bounds outside of time range');
        end
        start_ind = (interval(1) - t0) * fs;
    end
else
    start_ind = 1;
end

if isfinite(interval(2))

    if isempty(timeseries.starting_time)
        end_ind = fastsearch(timeseries.timestamps, interval(2), -1);
    else
        fs = timeseries.starting_time_rate;
        t0 = timeseries.starting_time;
        if interval(2) > (dims(1) * fs + t0)
            error('interval bounds outside of time range');
        end
        end_ind = (interval(2) - t0) * fs;
    end
else
    end_ind = Inf;
end

start = ones(1, length(dims));
start(end) = start_ind;

count = fliplr(dims);
count(end) = floor((end_ind - start_ind) / downsample_factor);

if ~isempty(electrode)
    start(end-1) = electrode;
    count(end-1) = 1;
end

if downsample_factor == 1
    data = timeseries.data.load(start, count)';
else
    stride = ones(1, length(dims));
    stride(end) = downsample_factor;
    data = timeseries.data.load(start, count, stride)';
end