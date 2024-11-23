function configObject = readDefaultChunkConfiguration()
% READDEFAULTCHUNKCONFIGURATION Reads the default chunking configuration from a JSON file.
%
%   configObject = READDEFAULTCHUNKCONFIGURATION() loads the default chunking
%   parameters from a JSON configuration file located in the 'configuration' 
%   directory within the MatNWB directory.
%
%   Output:
%       configObject - A MATLAB structure containing the chunking parameters
%                      defined in the JSON configuration file.
%
%   Example:
%       % Load the default chunk configuration
%       config = readDefaultChunkConfiguration();
%       disp(config);

    configFilePath = fullfile(misc.getMatnwbDir, 'configuration', 'chunk_params.json');
    configObject = jsondecode(fileread(configFilePath));
end
