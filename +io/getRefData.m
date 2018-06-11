function ref_data = getRefData(fid, ref)
switch class(ref)
    case 'types.untyped.RegionView'
        did = H5D.open(fid, ref.path);
        refspace = H5D.get_space(did);
        %by default, we use block mode.
        refspace = ref.get_selection(refspace);
        H5D.close(did);
    case 'types.untyped.ObjectView'
        refspace = -1;
end
ref_data = H5R.create(fid, ref.path, ref.reftype, refspace);
end