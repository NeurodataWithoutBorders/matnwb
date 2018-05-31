function ref_data = getRefData(fid, ref)
switch class(ref)
    case 'types.untyped.RegionView'
        did = H5D.open(fid, ref.path);
        refspace = H5D.get_space(did);
        H5S.select_hyperslab(...
            refspace, 'H5S_SELECT_SET', ref.range(1), [], ref.range(2), []);
        H5D.close(did);
    case 'types.untyped.ObjectView'
        refspace = -1;
end
ref_data = H5R.create(fid, ref.path, ref.reftype, refspace);
end