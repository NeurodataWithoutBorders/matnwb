function nwbExport(nwbFileObjects, filePaths, mode)
    %NWBEXPORT Writes an NWB file.
    %  nwbRead(nwb, filename) Writes the nwb object to a file at filename.
    %
    %  Example:
    %    % Generate Matlab code for the NWB objects from the core schema.
    %    % This only needs to be done once.
    %    generateCore('schema\core\nwb.namespace.yaml');
    %    % Create some fake fata and write
    %    nwb = NwbFile;
    %    nwb.session_start_time = datetime('now');
    %    nwb.identifier = 'EMPTY';
    %    nwb.session_description = 'empty test file';
    %    nwbExport(nwb, 'empty.nwb');
    %
    %  See also GENERATECORE, GENERATEEXTENSION, NWBFILE, NWBREAD

    arguments
        nwbFileObjects (1,:) NwbFile {mustBeNonempty}
        filePaths (1,:) string {mustBeNonzeroLengthText}
        mode (1,1) string {mustBeMember(mode, ["edit", "overwrite"])} = "edit"
    end

    if length(nwbFileObjects) ~= length(filePaths)
        error('NWB:Export:FilepathLengthMismatch', ...
            'Lists of NWB objects to export and list of file paths must be the same length.')
    end

    for iFiles = 1:length(nwbFileObjects)
        filePath = char(filePaths(iFiles));
        nwbFileObjects(iFiles).export(filePath, mode);
    end
end
