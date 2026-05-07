classdef DurationVectorData < types.hdmf_common.VectorData & types.untyped.DatasetClass
% DURATIONVECTORDATA - A 1-dimensional VectorData that stores durations in seconds.
%
% Required Properties:
%  data, description


% READONLY PROPERTIES
properties(SetAccess = protected)
    unit = "seconds"; %  (char) The unit of measurement for the durations, fixed to 'seconds'.
end
% OPTIONAL PROPERTIES
properties
    resolution; %  (single) The temporal resolution of the durations, in seconds. This is typically the sampling period (1 / sampling_rate), also known as the clock period, of the data acquisition system from which the durations were recorded or derived.
end

methods
    function obj = DurationVectorData(varargin)
        % DURATIONVECTORDATA - Constructor for DurationVectorData
        %
        % Syntax:
        %  durationVectorData = types.core.DURATIONVECTORDATA() creates a DurationVectorData object with unset property values.
        %
        %  durationVectorData = types.core.DURATIONVECTORDATA(Name, Value) creates a DurationVectorData object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (single) - Data property for dataset class (DurationVectorData)
        %
        %  - description (char) - Description of what these vectors represent.
        %
        %  - resolution (single) - The temporal resolution of the durations, in seconds. This is typically the sampling period (1 / sampling_rate), also known as the clock period, of the data acquisition system from which the durations were recorded or derived.
        %
        % Output Arguments:
        %  - durationVectorData (types.core.DurationVectorData) - A DurationVectorData object
        
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
        if strcmp(class(obj), 'types.core.DurationVectorData') %#ok<STISA>
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