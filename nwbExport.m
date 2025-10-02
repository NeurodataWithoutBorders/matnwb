function nwbExport(nwbFileObjects, filePaths, mode, options)
%NWBEXPORT - Writes an NWB file.
%
% Syntax:
%  NWBEXPORT(nwb, filename) Writes the nwb object to a file at filename.
%
%  NWBEXPORT(nwb, filename, Name, Value) Writes the nwb object using additional
%  options provided as name-value pairs.
%
% Input Arguments:
%   - nwb (NwbFile) - Nwb file object
%   - filename (string) - Filepath pointing to an NWB file.
%
% Name-Value Arguments (options):
%  Specify options using name-value arguments as Name1=Value1,...,NameN=ValueN, 
%  where Name is the argument name and Value is the corresponding value. 
%  - DatasetSettingsProfile (string) -
%    Default: "none". Name of a predefined configuration profile for dataset 
%    chunking and compression. Available options: "default", "cloud" or 
%    "archive". If this argument is specified, all datasets in the file larger 
%    than a threshold specified in the profile will be configured for chunking 
%    and compression.
%       
%  - DatasetSettings (string | struct) - 
%    Default: empty struct. Provide the filename of a custom configuration 
%    profile or an in-memory structure representing a configuration profile.
%
%  - OverrideDatasetSettings (logical) - 
%    Default: false. When true, existing DataPipe objects found in the file are reconfigured 
%    using the provided dataset settings.
%
% Usage:
%  Example 1 - Export an NWB file::
%
%    % Create an NWB object with some properties:
%    nwb = NwbFile;
%    nwb.session_start_time = datetime('now');
%    nwb.identifier = 'EMPTY';
%    nwb.session_description = 'empty test file';
%
%    % Write the nwb object to a file:
%    nwbExport(nwb, 'empty.nwb');
%
%  Example 2 - Export an NWB file using an older schema version::
%
%    % Generate classes for an older version of NWB schemas:
%    generateCore('2.5.0')
%
%    % Create an NWB object with some properties:
%    nwb = NwbFile;
%    nwb.session_start_time = datetime('now');
%    nwb.identifier = 'EMPTY';
%    nwb.session_description = 'empty test file';
%
%    % Write the nwb object to a file:
%    nwbExport(nwb, 'empty.nwb');
%
%  Example 3 - Export an NWB file using dataset settings tuned for cloud storage::
%
%    nwbExport(nwb, 'empty.nwb', 'DatasetSettingsProfile', 'cloud');
%
% See also:
%   generateCore, generateExtension, NwbFile, nwbRead

    arguments
        nwbFileObjects (1,:) NwbFile {mustBeNonempty}
        filePaths (1,:) string {matnwb.common.compatibility.mustBeNonzeroLengthText}
        mode (1,1) string {mustBeMember(mode, ["edit", "overwrite"])} = "edit"
        options.DatasetSettingsProfile (1,1) io.config.enum.ConfigurationProfile = "none"
        options.DatasetSettings = []
        options.OverrideDatasetSettings (1,1) logical = false
    end

    assert(length(nwbFileObjects) == length(filePaths), ...
        'NWB:Export:FilepathLengthMismatch', ...
        'Lists of NWB objects to export and list of file paths must be the same length.')

    shouldApplyDatasetSettings = ~isempty(options.DatasetSettings) || ...
        ~strcmp(string(options.DatasetSettingsProfile), "none");

    if shouldApplyDatasetSettings
        % Prepare dataset settings once and reuse across files.
        if ~isempty(options.DatasetSettings)
            datasetConfig = io.config.resolveDatasetConfiguration(options.DatasetSettings);
        else
            datasetConfig = io.config.readDatasetConfiguration(options.DatasetSettingsProfile);
        end
        for iFiles = 1:length(nwbFileObjects)
            nwbFileObjects(iFiles).applyDatasetSettings(...
                datasetConfig, 'OverrideExisting', options.OverrideDatasetSettings);
        end
    end

    for iFiles = 1:length(nwbFileObjects)
        filePath = char(filePaths(iFiles));
        nwbFileObjects(iFiles).export(filePath, mode);
    end
end
