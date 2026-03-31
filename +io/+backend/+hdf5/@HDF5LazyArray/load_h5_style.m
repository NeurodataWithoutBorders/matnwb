function data = load_h5_style(obj, varargin)
    % LOAD_H5_STYLE Read data from an HDF5 dataset.
    assert(length(varargin) ~= 1, 'NWB:DataStub:InvalidNumArguments', ...
        'calling load_h5_style with a single space id is no longer supported.');

    data = h5read(obj.filename, obj.path, varargin{:});

    if isstruct(data)
        % Compound types require consistent post-processing with
        % the rest of the HDF5 read path.
        fileId = H5F.open(obj.filename);
        datasetId = H5D.open(fileId, obj.path);
        fileSpaceId = H5D.get_space(datasetId);
        data = H5D.read(datasetId, 'H5ML_DEFAULT', fileSpaceId, fileSpaceId, ...
            'H5P_DEFAULT');
        data = io.parseCompound(datasetId, data);
        H5S.close(fileSpaceId);
        H5D.close(datasetId);
        H5F.close(fileId);
    else
        assert(~isstruct(obj.dataType), ...
            'NWB:DataStub:InconsistentCompoundType', ...
            ['DataStub has compound type descriptor, but loaded data is ' ...
            'not a struct. This indicates a file corruption or type ' ...
            'mismatch. Expected compound data for path: %s'], obj.path);

        switch obj.dataType
            case 'char'
                if iscellstr(data) && isscalar(data)
                    data = data{1};
                elseif isstring(data)
                    data = convertStringsToChars(data);
                end
            case 'logical'
                data = io.internal.h5.postprocess.toLogical(data);
        end
    end
end