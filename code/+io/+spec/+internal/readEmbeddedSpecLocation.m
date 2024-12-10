function specLocation = readEmbeddedSpecLocation(fid, specLocAttributeName)
    arguments
        fid (1,1) H5ML.id
        specLocAttributeName (1,1) string = '.specloc'
    end

    specLocation = '';
    try % Check .specloc
        attributeId = H5A.open(fid, specLocAttributeName);
        attributeCleanup = onCleanup(@(id) H5A.close(attributeId));
        referenceRawData = H5A.read(attributeId);
        specLocation = H5R.get_name(attributeId, 'H5R_OBJECT', referenceRawData);
    catch ME
        if ~strcmp(ME.identifier, 'MATLAB:imagesci:hdf5lib:libraryError')
            rethrow(ME);
        end % don't error if the attribute doesn't exist.
    end
end