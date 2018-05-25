function ref_data = getRefData(fid, ref)
switch class(ref)
    case 'types.untyped.RegionView'
        refspace = H5D.get_space(H5D.open(fid, ref.path));
        H5S.select_hyperslab(...
            refspace, 'H5S_SELECT_SET', ref.range(1), [], [], ref.range(2));
    case 'types.untyped.ObjectView'
        
        refspace = -1;
end
ref_data = H5R.create(fid, ref.path, ref.reftype, refspace);
end