classdef Clustering < types.core.NWBDataInterface & types.untyped.GroupClass
% CLUSTERING - DEPRECATED Clustered spike data, whether from automatic clustering tools (e.g., klustakwik) or as a result of manual sorting.
%
% Required Properties:
%  description, num, peak_over_rms, times


% REQUIRED PROPERTIES
properties
    description; % REQUIRED (char) Description of clusters or clustering, (e.g. cluster 0 is noise, clusters curated using Klusters, etc)
    num; % REQUIRED (int32) Cluster number of each event
    peak_over_rms; % REQUIRED (single) Maximum ratio of waveform peak to RMS on any channel in the cluster (provides a basic clustering metric).
    times; % REQUIRED (double) Times of clustered events, in seconds. This may be a link to times field in associated FeatureExtraction module.
end

methods
    function obj = Clustering(varargin)
        % CLUSTERING - Constructor for Clustering
        %
        % Syntax:
        %  clustering = types.core.CLUSTERING() creates a Clustering object with unset property values.
        %
        %  clustering = types.core.CLUSTERING(Name, Value) creates a Clustering object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - description (char) - Description of clusters or clustering, (e.g. cluster 0 is noise, clusters curated using Klusters, etc)
        %
        %  - num (int32) - Cluster number of each event
        %
        %  - peak_over_rms (single) - Maximum ratio of waveform peak to RMS on any channel in the cluster (provides a basic clustering metric).
        %
        %  - times (double) - Times of clustered events, in seconds. This may be a link to times field in associated FeatureExtraction module.
        %
        % Output Arguments:
        %  - clustering (types.core.Clustering) - A Clustering object
        
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        addParameter(p, 'num',[]);
        addParameter(p, 'peak_over_rms',[]);
        addParameter(p, 'times',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        obj.num = p.Results.num;
        obj.peak_over_rms = p.Results.peak_over_rms;
        obj.times = p.Results.times;
        if strcmp(class(obj), 'types.core.Clustering')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    function set.num(obj, val)
        obj.num = obj.validate_num(val);
    end
    function set.peak_over_rms(obj, val)
        obj.peak_over_rms = obj.validate_peak_over_rms(val);
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
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_num(obj, val)
        val = types.util.checkDtype('num', 'int32', val);
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
    function val = validate_peak_over_rms(obj, val)
        val = types.util.checkDtype('peak_over_rms', 'single', val);
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
            io.writeDataset(fid, [fullpath '/description'], obj.description);
        end
        if startsWith(class(obj.num), 'types.untyped.')
            refs = obj.num.export(fid, [fullpath '/num'], refs);
        elseif ~isempty(obj.num)
            io.writeDataset(fid, [fullpath '/num'], obj.num, 'forceArray');
        end
        if startsWith(class(obj.peak_over_rms), 'types.untyped.')
            refs = obj.peak_over_rms.export(fid, [fullpath '/peak_over_rms'], refs);
        elseif ~isempty(obj.peak_over_rms)
            io.writeDataset(fid, [fullpath '/peak_over_rms'], obj.peak_over_rms, 'forceArray');
        end
        if startsWith(class(obj.times), 'types.untyped.')
            refs = obj.times.export(fid, [fullpath '/times'], refs);
        elseif ~isempty(obj.times)
            io.writeDataset(fid, [fullpath '/times'], obj.times, 'forceArray');
        end
    end
end

end