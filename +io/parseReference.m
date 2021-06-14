function refobj = parseReference(did, tid, data)
szref = size(data);
%first dimension is always the raw buffer size
szref = szref(2:end);
if isscalar(szref)
    szref = [szref 1];
end
numref = prod(szref);
if H5T.equal(tid, 'H5T_STD_REF_OBJ')
    reftype = H5ML.get_constant_value('H5R_OBJECT');
else
    reftype = H5ML.get_constant_value('H5R_DATASET_REGION');
end
for i=1:numref
    refobj(i) = parseSingleRef(did, reftype, data(:,i));
end
refobj = reshape(refobj, szref);
end

function refobj = parseSingleRef(did, reftype, data)
target = H5R.get_name(did, reftype, data);

%% H5R_OBJECT
if reftype == H5ML.get_constant_value('H5R_OBJECT')
    refobj = types.untyped.ObjectView(target);
    return;
end

%% H5R_DATASET_REGION
if isempty(target)
    refobj = types.untyped.RegionView(target);
    return;
end
sid = H5R.get_region(did, reftype, data);

if H5ML.get_constant_value('H5S_SEL_HYPERSLABS') ~= H5S.get_select_type(sid)
    warning('NWB:ParseReference:UnsupportedSelectionType',...
        ['MatNWB does not support space selections other than hyperslab mode. '...
        'Ignoring other selections.']);
end

blocklist = flipud(H5S.get_select_hyper_blocklist(sid, 0, H5S.get_select_hyper_nblocks(sid)));
% Returns an (m x 2n) array, where m is the number of dimensions (or rank) of the dataspace.
% The 2n rows of Result contain the list of blocks. The first row contains the start
% coordinates of the first block, followed by the next row which contains the opposite
% corner coordinates, followed by the next row which contains the start coordinates of the
% second block,etc.
selections = cell(size(blocklist, 1), 1);
for i = 1:length(selections)
    prevSel = selections{i};
    blockDim = mat2cell(blocklist(i,:), 1, ones(1, (size(blocklist, 2) / 2)) + 1);
    for j = 1:length(blockDim)
        block = blockDim{j};
        blockDim{j} = (block(1):block(2))+1;
    end
    selections{i} = [prevSel cell2mat(blockDim)];
end

H5S.close(sid);
refobj = types.untyped.RegionView(target, selections{:});
end