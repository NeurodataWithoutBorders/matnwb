classdef SetEnvironmentVariableFixture < matlab.unittest.fixtures.Fixture
% UsesEnvironmentVariable Fixture for setting environment variables in tests.
%
%   This fixture reads an environment file containing key-value pairs and
%   sets the corresponding system environment variables prior to executing
%   tests. The expected format for the environment file is:
%
%       VARIABLE_NAME=VALUE
%
%   Lines that are empty or start with '#' (comments) are ignored.
%
%   The fixture first attempts to load environment variables from the file
%   "nwbtest.env" located in the "+tests" folder. If "nwbtest.env" is not 
%   found, it falls back to "nwbtest.default.env". When using the default file, 
%   the fixture only applies environment variables if they are not present
%   in the current list of environment variables.

    methods
        function setup(fixture) %#ok<MANU>
            
            applyFromFile = true;
            envFilePath = fullfile(misc.getMatnwbDir, '+tests', 'nwbtest.env');
            
            if ~isfile(envFilePath)
                envFilePath = fullfile(misc.getMatnwbDir, '+tests', 'nwbtest.default.env');
                applyFromFile = false;
            end

            if exist("loadenv", "file") == 2 
                envVariables = loadenv(envFilePath);
            else
                envVariables = readEnvFile(envFilePath);
            end

            envVariableNames = string( envVariables.keys() );
            if ~isrow(envVariableNames); envVariableNames = envVariableNames'; end
            
            for varName = envVariableNames
                varValue = envVariables(varName);
                if ~isenv(varName)
                    setenv(varName, varValue)
                elseif applyFromFile && ~isempty(char(varValue))
                    setenv(varName, varValue)
                end
            end
        end
    end
end

function envMap = readEnvFile(filename)
% readEnvFile Reads an environment file into a containers.Map.
%
%   envMap = readEnvFile(filename) reads the file specified by 'filename'
%   and returns a containers.Map where each key is a variable name and each
%   value is the corresponding value from the file.
%
%   Lines starting with '#' or empty lines are ignored.

    envMap = containers.Map;
    
    fileContent = fileread(filename);
    lines = strsplit(fileContent, newline);
    
    for i = 1:numel(lines)
        line = lines{i};
        if isempty(line) || startsWith(line, '#')
            continue;
        end
        
        % Find the first occurrence of '='
        idx = strfind(line, '=');
        if isempty(idx)
            continue; % ignore line
        end
        
        % Use the first '=' as the delimiter
        key = strtrim(line(1:idx(1)-1));
        value = strtrim(line(idx(1)+1:end));
        
        % Insert the key-value pair into the map
        envMap(key) = value;
    end
end
