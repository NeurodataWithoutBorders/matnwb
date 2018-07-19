function ref_data = getRefData(fid, ref)
refspace = cell(length(ref), 1);
switch class(ref)
    case 'types.untyped.RegionView'
        refpaths = {ref.path};
        for i=1:length(refpaths)
            did = H5D.open(fid, refpaths{i});
            refspace{i} = H5D.get_space(did);
            %by default, we use block mode.
            refspace{i} = ref(i).get_selection(refspace{i});
            H5D.close(did);
        end
        refsz = 12;
    case 'types.untyped.ObjectView'
        refspace(:) = {-1};
        refsz = 8;
end
ref_data = uint8(zeros(refsz, length(ref)));
for i=1:length(ref)
    ref_data(:, i) = H5R.create(fid, ref(i).path, ref(i).reftype, ...
        refspace{i});
end
end