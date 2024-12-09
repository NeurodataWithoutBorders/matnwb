function mustBeNwbFile(filePath)
% mustBeNwbFile - Check that file path points to existing file with .nwb extension
    arguments
        filePath (1,1) string {mustBeFile}
    end
    assert(endsWith(filePath, ".nwb", "IgnoreCase", true))
end