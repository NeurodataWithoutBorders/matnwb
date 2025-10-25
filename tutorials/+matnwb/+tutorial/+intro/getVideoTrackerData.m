function result = getVideoTrackerData()
    % Get some 2D trajectory
    data = matnwb.tutorial.intro.getRandomTrajectory();

    % Number of original points
    n = length(data);

    % Define original and new sample positions
    xOriginal = 1:n;
    xNew = linspace(1, n, n*3);

    % Preallocate result
    result = zeros(2, numel(xNew));

    % Interpolate each row separately
    result(1,:) = interp1(xOriginal, data(1,:), xNew, 'linear');
    result(2,:) = interp1(xOriginal, data(2,:), xNew, 'linear');
end
