function varValue = getEnvironmentVariable(varName)
% getEnvironmentVariable - Get value of environment variable from nwbtest.env
%
% Note: Recommended to use with MATLAB R2023a or newer.

    envFilePath = fullfile(misc.getMatnwbDir, '+tests', 'nwbtest.env');
    if ~isfile(envFilePath)
        envFilePath = fullfile(misc.getMatnwbDir, '+tests', 'nwbtest.template.env');
    end

    if exist("loadenv", "file") == 2
        D = loadenv(envFilePath);
        varValue = D(varName);
    else
        lines = readlines(envFilePath);
        isLineOfInterest = startsWith(lines, varName);
        if any(isLineOfInterest)
            splitLineOfInterest = split(lines(isLineOfInterest), '=');
            varValue = strtrim(splitLineOfInterest(2));
        else
            error('Variable with name "%s" was not found in list of environment variables', varName)
        end
    end 
end
