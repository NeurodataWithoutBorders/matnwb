function configObject = readDefaultChunkConfiguration()
% READDEFAULTCHUNKCONFIGURATION Reads the default chunking configuration from a JSON file.
%
% Syntax:
%   configObject = io.config.READDEFAULTCHUNKCONFIGURATION() loads the default 
%   chunking parameters from a JSON configuration file located in the
%   "configuration" folder inside the MatNWB directory.
%
% Output Arguments:
%   - configObject - A MATLAB structure containing the chunking parameters
%                      defined in the JSON configuration file.
%
% Example 1 - Load default dataset configurations::
%    % Load the default chunk configuration
%    config = readDefaultChunkConfiguration();
%    disp(config);

    configFilePath = fullfile(...
        misc.getMatnwbDir, ...
        'configuration', ...
        'cloud_dataset_configuration.json');

    configObject = jsondecode(fileread(configFilePath));
end
