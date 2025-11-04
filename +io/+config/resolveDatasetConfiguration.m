function datasetConfig = resolveDatasetConfiguration(input)
% resolveDatasetConfiguration - Resolves the dataset configuration based on the input.
%
% Syntax:
%   datasetConfig = io.config.resolveDatasetConfiguration(input) 
%   This function resolves NWB dataset configurations from the specified input, 
%   which can be a file path or a structure. If no input is provided, it 
%   uses the default NWB dataset configuration profile.
%
% Input Arguments:
%   input {mustBeStringOrStruct} - A value to resolve configurations for,
%   which can either be a string representing the file path to the
%   configurations or a struct containing the configurations directly.
%
% Output Arguments:
%   datasetConfig - The NWB dataset configurations, returned as a structure.

    arguments
        input {mustBeStringOrStruct} = struct.empty
    end

    if isempty(input)
        disp('No dataset settings provided, using default dataset settings profile.')
        datasetConfig = io.config.readDatasetConfiguration();
    
    elseif ischar(input) || (isstring(input) && isscalar(input))
        input = string(input);
        if isfile(input)
            datasetConfig = io.config.readDatasetConfiguration("FilePath", input);
        else
            datasetConfig = io.config.readDatasetConfiguration(input);
        end

    elseif isstruct(input)
        datasetConfig = input;
    end
end

function mustBeStringOrStruct(value)
    isValid = isempty(value) || ...
        ischar(value) || (isstring(value) && isscalar(value)) || ...
        isstruct(value);

    assert(isValid, ...
        'NWB:ResolveDatasetSettings:InvalidInput', ...
        ['Expected datasetSettings to be a string (profile name or filename) ' ...
        'or a struct (already loaded settings).'])
end
