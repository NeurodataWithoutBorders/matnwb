function specLocation = getEmbeddedSpecLocation(filename, options)
% getEmbeddedSpecLocation - Get location of embedded specs in NWB file
%
%   Note: Returns an empty string if the spec location does not exist
%
%   See also io.spec.internal.readEmbeddedSpecLocation

    arguments
        filename (1,1) string {matnwb.common.mustBeNwbFile}
        options.SpecLocAttributeName (1,1) string = '.specloc'
    end

    fid = H5F.open(filename);
    fileCleanup = onCleanup(@(id) H5F.close(fid) );
    specLocation = io.spec.internal.readEmbeddedSpecLocation(fid, options.SpecLocAttributeName);
end
