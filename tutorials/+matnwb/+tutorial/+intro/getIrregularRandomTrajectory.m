function [data, timepoints] = getIrregularRandomTrajectory()
    
    data = matnwb.tutorial.intro.getRandomTrajectory();

    samplingRate        = 10;              % 10 Hz sampling    
    jitter     = 0.02 * randn(1, size(data, 2));   % ±20 ms
    timepoints = (0:size(data, 2) - 1) / samplingRate + jitter; % Irregular sampling
end
