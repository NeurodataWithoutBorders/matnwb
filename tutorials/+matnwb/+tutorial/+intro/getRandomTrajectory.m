function result = getRandomTrajectory()
    samplingRate        = 10;              % 10 Hz sampling
    experimentDuration  = 30; 
    t = 0 : 1/samplingRate : experimentDuration;   % continuous timeline
    t = t(1:300);

    % random walk in metres
    rng(42);
    step      = 0.02* randn(2, numel(t));
    result    = cumsum(step,2);

    rng('default')
end
