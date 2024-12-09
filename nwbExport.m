function nwbExport(nwbFileObjects, filePaths, mode)
%NWBEXPORT - Writes an NWB file.
%
% Syntax:
%  NWBEXPORT(nwb, filename) Writes the nwb object to a file at filename.
%
% Input Arguments:
%   - nwb (NwbFile) - Nwb file object
%   - filename (string) - Filepath pointing to an NWB file.
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
% See also:
%   generateCore, generateExtension, NwbFile, nwbRead

    arguments
        nwbFileObjects (1,:) NwbFile {mustBeNonempty}
        filePaths (1,:) string {mustBeNonzeroLengthText}
        mode (1,1) string {mustBeMember(mode, ["edit", "overwrite"])} = "edit"
    end

    assert(length(nwbFileObjects) == length(filePaths), ...
        'NWB:Export:FilepathLengthMismatch', ...
        'Lists of NWB objects to export and list of file paths must be the same length.')

    for iFiles = 1:length(nwbFileObjects)
        filePath = char(filePaths(iFiles));
        nwbFileObjects(iFiles).export(filePath, mode);
    end
end
