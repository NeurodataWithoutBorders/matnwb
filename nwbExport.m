function nwbExport(nwbFileObjects, filePaths, mode, options)
%NWBEXPORT - Writes an NWB file.
%
% Syntax:
%  NWBEXPORT(nwb, filename) Writes the nwb object to a file at filename.
%
% Input Arguments:
%   - nwb (NwbFile) - Nwb file object
%   - filename (string) - Filepath pointing to an NWB file.
%
% Name-Value Arguments:
%  - DatasetSettingsProfile (string) -
%    Name of a predefined configuration profile. Available options:
%    "default", "cloud", "archive".
%       
%  - DatasetSettings (string | struct) - 
%    Apply dataset configuration prior to export. Provide a profile name 
%    accepted by io.config.readDatasetConfiguration (e.g. "default", "cloud",
%    "archive"), a filepath to a custom configuration profile or a configuration 
%    struct matching the format returned by that io.config.readDatasetConfiguration.
%
%  - OverrideDatasetSettings (logical) - 
%    When true, existing DataPipe objects found in the file are reconfigured 
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
