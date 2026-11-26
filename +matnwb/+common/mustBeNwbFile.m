function mustBeNwbFile(location)
% mustBeNwbFile - Check that a location names an existing file or folder
%
% Only existence is checked: some storage formats keep an NWB file in a
% folder, and the file name does not tell the format. Whether a storage
% backend can read the location is decided by io.backend.BackendFactory.
% Remote locations (s3:// URIs and http(s) URLs) are not checked.
    arguments
        location (1,1) string
    end
    if startsWith(location, "s3://", "IgnoreCase", true) || matnwb.common.isUrl(location)
        return
    end
    if ~isfile(location) && ~isfolder(location)
        error('NWB:validators:mustBeNwbFile', ...
            'The file or folder "%s" does not exist.', location)
    end
end
