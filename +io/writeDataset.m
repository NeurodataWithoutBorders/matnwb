function writeDataset(fid, fullpath, data, varargin)
    assert(isempty(varargin) || iscellstr(varargin),...
        'NWB:WriteDataset:InvalidStringFormat',...
        'options should be character arrays.');
    [tid, sid, data] = io.mapData2H5(fid, data, varargin{:});
    [~, dims, ~] = H5S.get_simple_extent_dims(sid);
    try
        dcpl = H5P.create('H5P_DATASET_CREATE');
        if any(strcmp('forceChunking', varargin))
            H5P.set_chunk(dcpl, dims)
        end
        did = H5D.create(fid, fullpath, tid, sid, dcpl);
        H5P.close(dcpl);
    catch ME
        if contains(ME.message, 'name already exists')
            did = H5D.open(fid, fullpath);
            create_plist = H5D.get_create_plist(did);
            edit_sid = H5D.get_space(did);
            [~, edit_dims, ~] = H5S.get_simple_extent_dims(edit_sid);
            layout = H5P.get_layout(create_plist);
            is_chunked = layout == H5ML.get_constant_value('H5D_CHUNKED');
            is_same_dims = all(edit_dims == dims);
            H5P.close(create_plist);
            H5S.close(edit_sid);
            
            if ~is_same_dims && is_chunked
                H5D.set_extent(did, dims);
            elseif ~is_same_dims
                warning('NWB:WriteDataset:ContinuousDatasetResize', ...
                    'Attempted to change size of continuous dataset `%s`.  Skipping.',...
                    fullpath);
                H5S.close(sid);
                H5D.close(did);
                return;
            end
        else
            rethrow(ME);
        end
    end
    if isReferenceType(tid) && isscalar(dims)
        writeReferenceBuffer(did, tid, sid, data);
    else
        H5D.write(did, tid, sid, sid, 'H5P_DEFAULT', data);
    end
    H5D.close(did);
    if isa(tid, 'H5ML.id')
        H5T.close(tid);
    end
    H5S.close(sid);
end

function writeReferenceBuffer(did, tid, sid, data)
    % writeReferenceBuffer - Write a reference data buffer to an open dataset.
    %
    % Reference datasets containing a null reference in their first element
    % cannot be written as a single buffer: MATLAB's H5D.write validates the
    % leading reference and rejects a null (all-zero) one on HDF5 1.14+
    % (bundled with MATLAB R2024a and newer). To avoid this, only the non-null
    % references are written, using element selection. The null slots retain
    % the dataset's default fill value (all zeros = null reference), which is
    % byte-identical to the output produced by earlier HDF5 releases.
    referenceSize = H5T.get_size(tid);
    buffer = reshape(data, referenceSize, []);
    isNullReference = all(buffer == 0, 1);
    if all(isNullReference)
        % Nothing to write; the dataset already reads back as null
        % references from its zero fill value.
    elseif any(isNullReference)
        validColumns = find(~isNullReference);
        fileSpace = H5D.get_space(did);
        % Coordinates are 0-based and must be double precision.
        H5S.select_elements(fileSpace, 'H5S_SELECT_SET', double(validColumns - 1));
        memorySpace = H5S.create_simple(1, numel(validColumns), numel(validColumns));
        H5D.write(did, tid, memorySpace, fileSpace, 'H5P_DEFAULT', buffer(:, validColumns));
        H5S.close(memorySpace);
        H5S.close(fileSpace);
    else
        H5D.write(did, tid, sid, sid, 'H5P_DEFAULT', data);
    end
end

function tf = isReferenceType(tid)
    % Object (H5T_STD_REF_OBJ) and region (H5T_STD_REF_DSETREG) reference
    % types are passed through as char identifiers by io.getBaseType.
    tf = (ischar(tid) || isstring(tid)) && startsWith(tid, 'H5T_STD_REF');
end