classdef TimestampVectorData < types.hdmf_common.VectorData & types.untyped.DatasetClass
% TIMESTAMPVECTORDATA - A 1-dimensional VectorData that stores timestamps in seconds from the session start time. Timestamp are not required to be sorted in time.
%
% Required Properties:
%  data, description


% READONLY PROPERTIES
properties(SetAccess = protected)
    unit = "seconds"; %  (char) The unit of measurement for the timestamps, fixed to 'seconds'.
end
% OPTIONAL PROPERTIES
properties
    resolution; %  (single) The temporal resolution of the timestamps, in seconds. This is typically the sampling period (1 / sampling_rate), also known as the clock period, of the data acquisition system from which the timestamps were recorded or derived.
end

methods
    function obj = TimestampVectorData(varargin)
        % TIMESTAMPVECTORDATA - Constructor for TimestampVectorData
        %
        % Syntax:
        %  timestampVectorData = types.core.TIMESTAMPVECTORDATA() creates a TimestampVectorData object with unset property values.
        %
        %  timestampVectorData = types.core.TIMESTAMPVECTORDATA(Name, Value) creates a TimestampVectorData object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (single) - Data property for dataset class (TimestampVectorData)
        %
        %  - description (char) - Description of what these vectors represent.
        %
        %  - resolution (single) - The temporal resolution of the timestamps, in seconds. This is typically the sampling period (1 / sampling_rate), also known as the clock period, of the data acquisition system from which the timestamps were recorded or derived.
        %
        % Output Arguments:
        %  - timestampVectorData (types.core.TimestampVectorData) - A TimestampVectorData object
        
        varargin = [{'unit' 'seconds'} varargin];
        obj = obj@types.hdmf_common.VectorData(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'resolution',[]);
        addParameter(p, 'unit',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.resolution = p.Results.resolution;
        obj.unit = p.Results.unit;
        
        % Only execute validation/setup code when called directly in this class's
        % constructor, not when invoked through superclass constructor chain
        if strcmp(class(obj), 'types.core.TimestampVectorData') %#ok<STISA>
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.resolution(obj, val)
        obj.resolution = obj.validate_resolution(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'single', val);
        types.util.validateShape('data', {[Inf]}, val)
    end
    function val = validate_resolution(obj, val)
        val = types.util.checkDtype('resolution', 'single', val);
        types.util.validateShape('resolution', {[1]}, val)
    end
    %% EXPORT
    function refs = export(obj, writer, fullpath, refs)
        refs = export@types.hdmf_common.VectorData(obj, writer, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.resolution)
            writer.writeAttribute([fullpath '/resolution'], obj.resolution);
        end
        writer.writeAttribute([fullpath '/unit'], obj.unit);
    end
end

end