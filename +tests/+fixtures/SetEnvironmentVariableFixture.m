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
            tests.util.setTestEnvironmentVariables()
        end
    end
end
