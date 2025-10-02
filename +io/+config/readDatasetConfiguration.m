function datasetConfig = readDatasetConfiguration(profile, options)
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
%
% Example 2 - Load dataset configurations from a specific file ::
%
%    datasetConfig = io.config.readDatasetConfiguration("FilePath", "configuration_file.json");
%    disp(datasetConfig);

    arguments
        profile (1,1) io.config.enum.ConfigurationProfile = "default"
        options.FilePath string {mustBeJsonFileOrEmpty} = string.empty
    end

    if profile == io.config.enum.ConfigurationProfile.none && isempty(options.FilePath)
        datasetConfig = [];
        return
    end

    % If FilePath is specified, we use that file
    if ~isempty(options.FilePath)
        configFilePath = options.FilePath;
    else
        filename = sprintf('%s_dataset_configuration.json', profile);
        configFilePath = fullfile(misc.getMatnwbDir, 'configuration', filename);
    end  
    
    datasetConfig = jsondecode(fileread(configFilePath));
    datasetConfig = datasetConfig.datasetSpecifications;
    
    datasetConfig = io.config.internal.applyCustomMatNWBPropertyNames(datasetConfig);
    datasetConfig = io.config.internal.flipChunkDimensions(datasetConfig);
end

function mustBeJsonFileOrEmpty(value)
%MUSTBEJSONFILEOREMPTY Validate that input is a JSON file path or empty
%
%   mustBeJsonFileOrEmpty(VALUE) throws an error if VALUE is not empty and
%   not a character vector or string scalar ending with '.json' (case-insensitive).

    arguments
        value string
    end

    if isempty(value)
        return
    end

    assert(~isscalar(value), ...
        "NWB:validator:mustBeJsonFileOrEmpty:InvalidInput", ...
        "Value must be a string scalar, character vector, or empty.");

    assert(endsWith(value, ".json", "IgnoreCase", true), ...
        "NWB:validator:mustBeJsonFileOrEmpty:InvalidFileType", ...
        "Value must end with '.json'.");

    assert(exist(value, "file") == 2, ...
        "NWB:validator:mustBeJsonFileOrEmpty:FileMustExist", ...
            "Value must be the name of an existing json file.")
end
