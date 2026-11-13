function Reference = parseReference(datasetId, typeId, data, targetResolver)
    % targetResolver (optional) resolves the path each reference points to.
    % Without one, every reference is resolved with H5R.get_name, which
    % searches the whole file. See io.backend.hdf5.ReferenceTargetResolver.
    if nargin < 4
        targetResolver = [];
    end
    referenceSize = size(data);
    %first dimension is always the raw buffer size
    referenceSize = referenceSize(2:end);
    if isscalar(referenceSize)
        referenceSize = [referenceSize 1];
    end
    totalNumReferences = prod(referenceSize);
    if H5T.equal(typeId, 'H5T_STD_REF_OBJ')
        referenceType = H5ML.get_constant_value('H5R_OBJECT');
    else
        referenceType = H5ML.get_constant_value('H5R_DATASET_REGION');
    end
    for iReference = 1:totalNumReferences
        Reference(iReference) = parseSingleReference( ...
            datasetId, referenceType, data(:,iReference), targetResolver);
    end
    Reference = reshape(Reference, referenceSize);
end

function Reference = parseSingleReference(datasetId, referenceType, data, targetResolver)
    if isempty(targetResolver)
        target = H5R.get_name(datasetId, referenceType, data);
    else
        target = targetResolver.resolve(datasetId, referenceType, data);
    end

    %% H5R_OBJECT
    if referenceType == H5ML.get_constant_value('H5R_OBJECT')
        Reference = types.untyped.ObjectView(target);
        return;
    end

    %% H5R_DATASET_REGION
    if isempty(target)
        Reference = types.untyped.RegionView(target);
        return;
    end
    spaceId = H5R.get_region(datasetId, referenceType, data);

    if H5ML.get_constant_value('H5S_SEL_HYPERSLABS') ~= H5S.get_select_type(spaceId)
        warning('NWB:ParseReference:UnsupportedSelectionType',...
            ['MatNWB does not support space selections other than hyperslab mode. '...
            'Ignoring other selections.']);
    end

    numHyperBlocks = H5S.get_select_hyper_nblocks(spaceId);
    selectionBlock = flipud(H5S.get_select_hyper_blocklist(spaceId, 0, numHyperBlocks));
    % Returns an (m x 2n) array, where m is the number of dimensions (or rank) of the dataspace.
    % The 2n rows of Result contain the list of blocks. The first row contains the start
    % coordinates of the first block, followed by the next row which contains the opposite
    % corner coordinates, followed by the next row which contains the start coordinates of the
    % second block,etc.
    selections = cell(size(selectionBlock, 1), 1);
    selectionCellSize = {1, (ones(1, (size(selectionBlock, 2) / 2)) + 1)};
    for iSelection = 1:length(selections)
        previousSelection = selections{iSelection};
        blockDimension = mat2cell(selectionBlock(iSelection,:), selectionCellSize{:});
        for iDimension = 1:length(blockDimension)
            block = blockDimension{iDimension};
            blockDimension{iDimension} = (block(1):block(2))+1;
        end
        selections{iSelection} = [previousSelection cell2mat(blockDimension)];
    end

    H5S.close(spaceId);
    Reference = types.untyped.RegionView(target, selections{:});
end