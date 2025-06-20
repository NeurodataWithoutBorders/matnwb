classdef VectorIndex < types.hdmf_common.VectorData & types.untyped.DatasetClass
% VECTORINDEX - Used with VectorData to encode a ragged array. An array of indices into the first dimension of the target VectorData, and forming a map between the rows of a DynamicTable and the indices of the VectorData. The name of the VectorIndex is expected to be the name of the target VectorData object followed by "_index".
%
% Required Properties:
%  data, description, target


% REQUIRED PROPERTIES
properties
    target; % REQUIRED (Object reference to VectorData) Reference to the target dataset that this index applies to.
end

methods
    function obj = VectorIndex(varargin)
        % VECTORINDEX - Constructor for VectorIndex
        %
        % Syntax:
        %  vectorIndex = types.hdmf_common.VECTORINDEX() creates a VectorIndex object with unset property values.
        %
        %  vectorIndex = types.hdmf_common.VECTORINDEX(Name, Value) creates a VectorIndex object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (uint8) - No description
        %
        %  - description (char) - Description of what these vectors represent.
        %
        %  - resolution (double) - NOTE: this is a special value for compatibility with the Units table and is only written to file when detected to be in that specific HDF5 Group. The smallest possible difference between two spike times. Usually 1 divided by the acquisition sampling rate from which spike times were extracted, but could be larger if the acquisition time series was downsampled or smaller if the acquisition time series was smoothed/interpolated and it is possible for the spike time to be between samples.
        %
        %  - sampling_rate (single) - NOTE: this is a special value for compatibility with the Units table and is only written to file when detected to be in that specific HDF5 Group. Must be Hertz
        %
        %  - target (Object reference to VectorData) - Reference to the target dataset that this index applies to.
        %
        % Output Arguments:
        %  - vectorIndex (types.hdmf_common.VectorIndex) - A VectorIndex object
        
        obj = obj@types.hdmf_common.VectorData(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'target',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.target = p.Results.target;
        if strcmp(class(obj), 'types.hdmf_common.VectorIndex')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.target(obj, val)
        obj.target = obj.validate_target(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'uint8', val);
    end
    function val = validate_target(obj, val)
        % Reference to type `VectorData`
        val = types.util.checkDtype('target', 'types.untyped.ObjectView', val);
        types.util.validateShape('target', {[1]}, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.VectorData(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        io.writeAttribute(fid, [fullpath '/target'], obj.target);
    end
end

end