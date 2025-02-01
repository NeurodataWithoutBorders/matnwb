classdef ClusterWaveforms < types.core.NWBDataInterface & types.untyped.GroupClass
% CLUSTERWAVEFORMS - DEPRECATED The mean waveform shape, including standard deviation, of the different clusters. Ideally, the waveform analysis should be performed on data that is only high-pass filtered. This is a separate module because it is expected to require updating. For example, IMEC probes may require different storage requirements to store/display mean waveforms, requiring a new interface or an extension of this one.
%
% Required Properties:
%  waveform_filtering, waveform_mean, waveform_sd


% REQUIRED PROPERTIES
properties
    clustering_interface; % REQUIRED Clustering
    waveform_filtering; % REQUIRED (char) Filtering applied to data before generating mean/sd
    waveform_mean; % REQUIRED (single) The mean waveform for each cluster, using the same indices for each wave as cluster numbers in the associated Clustering module (i.e, cluster 3 is in array slot [3]). Waveforms corresponding to gaps in cluster sequence should be empty (e.g., zero- filled)
    waveform_sd; % REQUIRED (single) Stdev of waveforms for each cluster, using the same indices as in mean
end

methods
    function obj = ClusterWaveforms(varargin)
        % CLUSTERWAVEFORMS - Constructor for ClusterWaveforms
        %
        % Syntax:
        %  clusterWaveforms = types.core.CLUSTERWAVEFORMS() creates a ClusterWaveforms object with unset property values.
        %
        %  clusterWaveforms = types.core.CLUSTERWAVEFORMS(Name, Value) creates a ClusterWaveforms object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - clustering_interface (Clustering) - Link to Clustering interface that was the source of the clustered data
        %
        %  - waveform_filtering (char) - Filtering applied to data before generating mean/sd
        %
        %  - waveform_mean (single) - The mean waveform for each cluster, using the same indices for each wave as cluster numbers in the associated Clustering module (i.e, cluster 3 is in array slot [3]). Waveforms corresponding to gaps in cluster sequence should be empty (e.g., zero- filled)
        %
        %  - waveform_sd (single) - Stdev of waveforms for each cluster, using the same indices as in mean
        %
        % Output Arguments:
        %  - clusterWaveforms (types.core.ClusterWaveforms) - A ClusterWaveforms object
        
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'clustering_interface',[]);
        addParameter(p, 'waveform_filtering',[]);
        addParameter(p, 'waveform_mean',[]);
        addParameter(p, 'waveform_sd',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.clustering_interface = p.Results.clustering_interface;
        obj.waveform_filtering = p.Results.waveform_filtering;
        obj.waveform_mean = p.Results.waveform_mean;
        obj.waveform_sd = p.Results.waveform_sd;
        if strcmp(class(obj), 'types.core.ClusterWaveforms')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.clustering_interface(obj, val)
        obj.clustering_interface = obj.validate_clustering_interface(val);
    end
    function set.waveform_filtering(obj, val)
        obj.waveform_filtering = obj.validate_waveform_filtering(val);
    end
    function set.waveform_mean(obj, val)
        obj.waveform_mean = obj.validate_waveform_mean(val);
    end
    function set.waveform_sd(obj, val)
        obj.waveform_sd = obj.validate_waveform_sd(val);
    end
    %% VALIDATORS
    
    function val = validate_clustering_interface(obj, val)
        if isa(val, 'types.untyped.SoftLink')
            if isprop(val, 'target')
                types.util.checkDtype('clustering_interface', 'types.core.Clustering', val.target);
            end
        else
            val = types.util.checkDtype('clustering_interface', 'types.core.Clustering', val);
            if ~isempty(val)
                val = types.untyped.SoftLink(val);
            end
        end
    end
    function val = validate_waveform_filtering(obj, val)
        val = types.util.checkDtype('waveform_filtering', 'char', val);
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
    function val = validate_waveform_mean(obj, val)
        val = types.util.checkDtype('waveform_mean', 'single', val);
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
        validshapes = {[Inf,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_waveform_sd(obj, val)
        val = types.util.checkDtype('waveform_sd', 'single', val);
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
        validshapes = {[Inf,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.clustering_interface.export(fid, [fullpath '/clustering_interface'], refs);
        if startsWith(class(obj.waveform_filtering), 'types.untyped.')
            refs = obj.waveform_filtering.export(fid, [fullpath '/waveform_filtering'], refs);
        elseif ~isempty(obj.waveform_filtering)
            io.writeDataset(fid, [fullpath '/waveform_filtering'], obj.waveform_filtering);
        end
        if startsWith(class(obj.waveform_mean), 'types.untyped.')
            refs = obj.waveform_mean.export(fid, [fullpath '/waveform_mean'], refs);
        elseif ~isempty(obj.waveform_mean)
            io.writeDataset(fid, [fullpath '/waveform_mean'], obj.waveform_mean, 'forceArray');
        end
        if startsWith(class(obj.waveform_sd), 'types.untyped.')
            refs = obj.waveform_sd.export(fid, [fullpath '/waveform_sd'], refs);
        elseif ~isempty(obj.waveform_sd)
            io.writeDataset(fid, [fullpath '/waveform_sd'], obj.waveform_sd, 'forceArray');
        end
    end
end

end