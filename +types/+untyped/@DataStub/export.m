function refs = export(obj, fid, fullpath, refs)
    
    % If exporting to the same file this DataStub originates from, skip export.
    src_fid = H5F.open(obj.filename);
    src_filename = H5F.get_name(src_fid);
    dest_filename = H5F.get_name(fid);
    if strcmp(src_filename, dest_filename)
        return;
    end
    
    src_did = H5D.open(src_fid, obj.path);
    src_tid = H5D.get_type(src_did);

    % Check for compound data type refs
    if H5T.get_class(src_tid) == H5ML.get_constant_value('H5T_COMPOUND')
        isCompoundDatasetWithReference = isCompoundWithReference(src_tid);
    else
        isCompoundDatasetWithReference = false;
    end

    % If dataset is compound and contains reference types, data needs to be 
    % manually read and written to the new file. This is due to a bug in
    % the hdf5 library (see e.g. https://github.com/HDFGroup/hdf5/issues/3429)
    if isCompoundDatasetWithReference
        % This requires loading the entire table.
        % Due to this HDF5 library's inability to delete/update
        % dataset data, this is unfortunately required.
        data = H5D.read(src_did);

        % Use io.parseCompound to consistently handle references, character arrays, and logical types,
        % ensuring all data types are properly postprocessed in line with the rest of the codebase.
        data = io.parseCompound(src_did, data);
        io.writeCompound(fid, fullpath, data);

    elseif ~H5L.exists(fid, fullpath, 'H5P_DEFAULT')
        % copy data over and return destination.
        ocpl = H5P.create('H5P_OBJECT_COPY');
        lcpl = H5P.create('H5P_LINK_CREATE');
        H5O.copy(src_fid, obj.path, fid, fullpath, ocpl, lcpl);
        H5P.close(ocpl);
        H5P.close(lcpl);
    end
    H5T.close(src_tid);
    H5D.close(src_did);
    H5F.close(src_fid);
end

function hasReference = isCompoundWithReference(src_tid)
    hasReference = false;

    ncol = H5T.get_nmembers(src_tid);
    refTypeConst = H5ML.get_constant_value('H5T_REFERENCE');
    
    for i = 1:ncol
        subclass = H5T.get_member_class(src_tid, i-1);
        if subclass == refTypeConst
            hasReference = true;
            return
        end
    end
end
