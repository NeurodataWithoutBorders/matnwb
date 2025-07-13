function result = getVideoTrackerData()
    data = matnwb.tutorial.intro.getRandomTrajectory();

    result = zeros(2, length(data)*3);
    result(1,:) = interp(data(1,:), 3);
    result(2,:) = interp(data(2,:), 3);
end
