function refs = export(obj, fid, fullpath, refs)
    %Check for compound data type refs
    src_fid = H5F.open(obj.filename);
    % if filenames are the same, then do nothing
    src_filename = H5F.get_name(src_fid);
    dest_filename = H5F.get_name(fid);
    if strcmp(src_filename, dest_filename)
        return;
    end
    
    src_did = H5D.open(src_fid, obj.path);
    src_tid = H5D.get_type(src_did);
    src_sid = H5D.get_space(src_did);
    ref_i = false;
    char_i = false;
    member_name = {};
    ref_tid = {};
    if H5T.get_class(src_tid) == H5ML.get_constant_value('H5T_COMPOUND')
        ncol = H5T.get_nmembers(src_tid);
        ref_i = false(ncol, 1);
        member_name = cell(ncol, 1);
        char_i = false(ncol, 1);
        ref_tid = cell(ncol, 1);
        refTypeConst = H5ML.get_constant_value('H5T_REFERENCE');
        strTypeConst = H5ML.get_constant_value('H5T_STRING');
        for i = 1:ncol
            member_name{i} = H5T.get_member_name(src_tid, i-1);
            subclass = H5T.get_member_class(src_tid, i-1);
            subtid = H5T.get_member_type(src_tid, i-1);
            char_i(i) = subclass == strTypeConst && ...
                ~H5T.is_variable_str(subtid);
            if subclass == refTypeConst
                ref_i(i) = true;
                ref_tid{i} = subtid;
            end
        end
    end
    
    %manually load the data struct
    if any(ref_i)
        %This requires loading the entire table.
        %Due to this HDF5 library's inability to delete/update
        %dataset data, this is unfortunately required.
        ref_tid = ref_tid(~cellfun('isempty', ref_tid));
        data = H5D.read(src_did);
        
        refNames = member_name(ref_i);
        for i=1:length(refNames)
            data.(refNames{i}) = io.parseReference(src_did, ref_tid{i}, ...
                data.(refNames{i}));
        end
        
        strNames = member_name(char_i);
        for i=1:length(strNames)
            s = data.(strNames{i}) .';
            data.(strNames{i}) = mat2cell(s, ones(size(s,1),1));
        end
        
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
    H5S.close(src_sid);
    H5D.close(src_did);
    H5F.close(src_fid);
end