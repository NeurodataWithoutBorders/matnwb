function mustBeNwbFile(filePath)
% mustBeNwbFile - Check that path points to an existing NWB file or Zarr store
%
%   Accepts a file with a ".nwb" extension or a Zarr directory store with a
%   ".zarr" extension.
    arguments
        filePath (1,1) string {matnwb.common.compatibility.mustBeFile}
    end
    if ~startsWith(filePath, "s3://", "IgnoreCase", true)
        assert(endsWith(filePath, [".nwb", ".zarr"], "IgnoreCase", true))
    end
end
