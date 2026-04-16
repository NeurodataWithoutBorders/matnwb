function data = load_h5_style(obj, varargin)
% load_h5_style - Read data from HDF5 dataset.
%   DATA = LOAD_H5_STYLE() retrieves all of the data.
%
%   DATA = LOAD_H5_STYLE(START,COUNT) reads a subset of data. START is
%   the one-based index of the first element to be read.
%   COUNT defines how many elements to read along each dimension.  If a
%   particular element of COUNT is Inf, data is read until the end of the
%   corresponding dimension.
%
%   DATA = LOAD_H5_STYLE(START,COUNT,STRIDE) reads a strided subset of
%   data. STRIDE is the inter-element spacing along each
%   data set extent and defaults to one along each extent.

    assert(length(varargin) ~= 1, 'NWB:DataStub:InvalidNumArguments',...
        'calling load_h5_style with a single space id is no longer supported.');

    data = h5read(obj.Filename, obj.DatasetPath, varargin{:});

    if isstruct(data)
        % Compound type - data loaded as struct by h5read
        fid = H5F.open(obj.Filename);
        did = H5D.open(fid, obj.DatasetPath);
        fsid = H5D.get_space(did);
        % Bug: This will read all the data
        data = H5D.read(did, 'H5ML_DEFAULT', fsid, fsid,...
            'H5P_DEFAULT');
        data = io.parseCompound(did, data);
        H5S.close(fsid);
        H5D.close(did);
        H5F.close(fid);
    else
        % Non-compound types - apply type-specific post-processing

        % Validate: if dataType is struct, data must also be struct
        assert( ~isstruct(obj.dataType), ...
            'NWB:DataStub:InconsistentCompoundType', ...
            ['DataStub has compound type descriptor, but loaded data is '...
            'not a struct. This indicates a file corruption or type '...
            'mismatch. Expected compound data for path: %s'], obj.DatasetPath);

        % Apply type-specific transformations for simple types
        switch obj.dataType
            case 'char'
                % dataset strings are defaulted to cell arrays regardless of size
                if iscellstr(data) && isscalar(data)
                    data = data{1};
                elseif isstring(data)
                    data = convertStringsToChars(data);
                end
            case 'logical'
                % data assumed to be cell array of enum string values
                data = io.internal.h5.postprocess.toLogical(data);
        end
    end
    % h5read returns data in MATLAB F-order. In schema_style the user expects
    % C-order (slowest dim first), so permute to reverse the dimension order.
    % Skip for 1-D data and non-array types (char, cell, struct).
    if ~matnwb.preference.shouldFlipDimensions() ...
            && (isnumeric(data) || islogical(data)) ...
            && ~isvector(data)
        data = permute(data, fliplr(1:ndims(data)));
    end
end
