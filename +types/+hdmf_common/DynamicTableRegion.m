classdef DynamicTableRegion < types.hdmf_common.VectorData & types.untyped.DatasetClass
% DYNAMICTABLEREGION - DynamicTableRegion provides a link from one table to an index or region of another. The `table` attribute is a link to another `DynamicTable`, indicating which table is referenced, and the data is int(s) indicating the row(s) (0-indexed) of the target array. `DynamicTableRegion`s can be used to associate rows with repeated meta-data without data duplication. They can also be used to create hierarchical relationships between multiple `DynamicTable`s. `DynamicTableRegion` objects may be paired with a `VectorIndex` object to create ragged references, so a single cell of a `DynamicTable` can reference many rows of another `DynamicTable`.
%
% Required Properties:
%  data


% REQUIRED PROPERTIES
properties
    table; % REQUIRED (Object reference to DynamicTable) Reference to the DynamicTable object that this region applies to.
end

methods
    function obj = DynamicTableRegion(varargin)
        % DYNAMICTABLEREGION - Constructor for DynamicTableRegion
        %
        % Syntax:
        %  dynamicTableRegion = types.hdmf_common.DYNAMICTABLEREGION() creates a DynamicTableRegion object with unset property values.
        %
        %  dynamicTableRegion = types.hdmf_common.DYNAMICTABLEREGION(Name, Value) creates a DynamicTableRegion object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (int8) - No description
        %
        %  - description (char) - Description of what this table region points to.
        %
        %  - resolution (double) - NOTE: this is a special value for compatibility with the Units table and is only written to file when detected to be in that specific HDF5 Group. The smallest possible difference between two spike times. Usually 1 divided by the acquisition sampling rate from which spike times were extracted, but could be larger if the acquisition time series was downsampled or smaller if the acquisition time series was smoothed/interpolated and it is possible for the spike time to be between samples.
        %
        %  - sampling_rate (single) - NOTE: this is a special value for compatibility with the Units table and is only written to file when detected to be in that specific HDF5 Group. Must be Hertz
        %
        %  - table (Object reference to DynamicTable) - Reference to the DynamicTable object that this region applies to.
        %
        % Output Arguments:
        %  - dynamicTableRegion (types.hdmf_common.DynamicTableRegion) - A DynamicTableRegion object
        
        obj = obj@types.hdmf_common.VectorData(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        addParameter(p, 'description',[]);
        addParameter(p, 'table',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        obj.description = p.Results.description;
        obj.table = p.Results.table;
        if strcmp(class(obj), 'types.hdmf_common.DynamicTableRegion')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.table(obj, val)
        obj.table = obj.validate_table(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'int8', val);
    end
    function val = validate_description(obj, val)
        val = types.util.checkDtype('description', 'char', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_table(obj, val)
        % Reference to type `DynamicTable`
        val = types.util.checkDtype('table', 'types.untyped.ObjectView', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.VectorData(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        io.writeAttribute(fid, [fullpath '/table'], obj.table);
    end
end

end