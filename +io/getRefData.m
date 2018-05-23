function ref_data = getRefData(fid, ref)
try
    switch class(ref)
        case 'types.untyped.RegionView'
            refspace = H5D.get_space(H5D.open(fid, ref.path));
            H5S.select_hyperslab(...
                refspace, 'H5S_SELECT_SET', ref.range(1), [], [], ref.range(2)); 
        case 'types.untyped.ObjectView'
            
            refspace = -1;
    end
    ref_data = H5R.create(fid, ref.path, ref.reftype, refspace);
catch ME
    if any(contains(ME.message, {'H5R_create           object not found'...
            'H5Dopen1             not found'}))
        ref_data = uint8(zeros(1, H5T.get_size(ref.type)));
    else
        rethrow(ME);
    end
end
end