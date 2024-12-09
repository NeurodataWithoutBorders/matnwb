classdef FeatureExtraction < types.core.NWBDataInterface & types.untyped.GroupClass
% FEATUREEXTRACTION - Features, such as PC1 and PC2, that are extracted from signals stored in a SpikeEventSeries or other source.
%
% Required Properties:
%  description, electrodes, features, times


% REQUIRED PROPERTIES
properties
    description; % REQUIRED (char) Description of features (eg, ''PC1'') for each of the extracted features.
    electrodes; % REQUIRED (DynamicTableRegion) DynamicTableRegion pointer to the electrodes that this time series was generated from.
    features; % REQUIRED (single) Multi-dimensional array of features extracted from each event.
    times; % REQUIRED (double) Times of events that features correspond to (can be a link).
end

methods
    function obj = FeatureExtraction(varargin)
        % FEATUREEXTRACTION - Constructor for FeatureExtraction
        %
        % Syntax:
        %  featureExtraction = types.core.FEATUREEXTRACTION() creates a FeatureExtraction object with unset property values.
        %
        %  featureExtraction = types.core.FEATUREEXTRACTION(Name, Value) creates a FeatureExtraction object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - description (char) - Description of features (eg, ''PC1'') for each of the extracted features.
        %
        %  - electrodes (DynamicTableRegion) - DynamicTableRegion pointer to the electrodes that this time series was generated from.
        %
        %  - features (single) - Multi-dimensional array of features extracted from each event.
        %
        %  - times (double) - Times of events that features correspond to (can be a link).
        %
        % Output Arguments:
        %  - featureExtraction (types.core.FeatureExtraction) - A FeatureExtraction object
        
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        addParameter(p, 'electrodes',[]);
        addParameter(p, 'features',[]);
        addParameter(p, 'times',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        obj.electrodes = p.Results.electrodes;
        obj.features = p.Results.features;
        obj.times = p.Results.times;
        if strcmp(class(obj), 'types.core.FeatureExtraction')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    function set.electrodes(obj, val)
        obj.electrodes = obj.validate_electrodes(val);
    end
    function set.features(obj, val)
        obj.features = obj.validate_features(val);
    end
    function set.times(obj, val)
        obj.times = obj.validate_times(val);
    end
    %% VALIDATORS
    
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
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_electrodes(obj, val)
        val = types.util.checkDtype('electrodes', 'types.hdmf_common.DynamicTableRegion', val);
    end
    function val = validate_features(obj, val)
        val = types.util.checkDtype('features', 'single', val);
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
        validshapes = {[Inf,Inf,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_times(obj, val)
        val = types.util.checkDtype('times', 'double', val);
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
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if startsWith(class(obj.description), 'types.untyped.')
            refs = obj.description.export(fid, [fullpath '/description'], refs);
        elseif ~isempty(obj.description)
            io.writeDataset(fid, [fullpath '/description'], obj.description, 'forceArray');
        end
        refs = obj.electrodes.export(fid, [fullpath '/electrodes'], refs);
        if startsWith(class(obj.features), 'types.untyped.')
            refs = obj.features.export(fid, [fullpath '/features'], refs);
        elseif ~isempty(obj.features)
            io.writeDataset(fid, [fullpath '/features'], obj.features, 'forceArray');
        end
        if startsWith(class(obj.times), 'types.untyped.')
            refs = obj.times.export(fid, [fullpath '/times'], refs);
        elseif ~isempty(obj.times)
            io.writeDataset(fid, [fullpath '/times'], obj.times, 'forceArray');
        end
    end
end

end