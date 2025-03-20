function datasetConfig = readDatasetConfiguration(profile)
% READDATASETCONFIGURATION Reads the default dataset configuration from a JSON file.
%
% Syntax:
%  configObject = io.config.READDATASETCONFIGURATION() loads the default
%  dataset configuration parameters from a JSON file located in the
%  "configuration" folder in the MatNWB root directory.
%
%  configObject = io.config.READDATASETCONFIGURATION(profile) loads the
%  dataset configuration parameters for the specified "configuration profile"
%  from a JSON file located in the "configuration" folder in the MatNWB root 
%  directory.
%
% Output Arguments:
%   - datasetConfig - A MATLAB structure containing the dataset configuration
%                     parameters (chunking & compression) defined in the JSON 
%                     configuration file.
%
% Example 1 - Load default dataset configurations::
%
%    % Load the default dataset configuration
%    datasetConfig = io.config.readDatasetConfiguration();
%    disp(datasetConfig);

    arguments
        profile (1,1) string {mustBeMember(profile, [ ...
            "default", ...
            "cloud", ...
            "archive"
            ])} = "default"
    end

    filename = sprintf('%s_dataset_configuration.json', profile);

    configFilePath = fullfile(misc.getMatnwbDir, 'configuration', filename);
    datasetConfig = jsondecode(fileread(configFilePath));
    datasetConfig = datasetConfig.datasetSpecifications;
    
    datasetConfig = io.config.internal.applyCustomMatNWBPropertyNames(datasetConfig);
    datasetConfig = io.config.internal.flipChunkDimensions(datasetConfig);
end
