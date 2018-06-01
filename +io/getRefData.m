function ref_data = getRefData(fid, ref)
switch class(ref)
    case 'types.untyped.RegionView'
        did = H5D.open(fid, ref.path);
        refspace = H5D.get_space(did);
        switch ref.mode
            case 'point'
                for i=1:length(ref.region)
                    if i == 1
                        sel_mode = 'H5S_SELECT_SET';
                    else
                        sel_mode = 'H5S_SELECT_OR';
                    end
                    H5S.select_elements(refspace, sel_mode,...
                        ref.region{i} - 1);
                end
            case 'block'
                for i=1:length(ref.region)
                    reg = ref.region{i} - 1; %switch to 0-based indexing
                    if i == 1
                        sel_mode = 'H5S_SELECT_SET';
                    else
                        sel_mode = 'H5S_SELECT_OR';
                    end
                    % [reg(1)..reg(2))
                    H5S.select_hyperslab(refspace, sel_mode,...
                        reg(1), [], [], reg(2) - reg(1) + 1);
                end
            case 'all'
                H5S.select_all(refspace);
            case 'none'
                H5S.select_none(refspace);
        end
        H5D.close(did);
    case 'types.untyped.ObjectView'
        refspace = -1;
end
ref_data = H5R.create(fid, ref.path, ref.reftype, refspace);
end