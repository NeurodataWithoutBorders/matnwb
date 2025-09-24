function mustBeNwbFile(filePath)
% mustBeNwbFile - Check that file path points to existing file with .nwb extension
    arguments
        filePath (1,1) string {matnwb.common.compatibility.mustBeFile}
    end
    if ~startsWith(filePath, "s3://", "IgnoreCase", true)
        assert(endsWith(filePath, ".nwb", "IgnoreCase", true))
    end
end
