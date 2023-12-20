classdef VectorData < types.hdmf_common.Data & types.untyped.DatasetClass
% VECTORDATA An n-dimensional dataset representing a column of a DynamicTable. If used without an accompanying VectorIndex, first dimension is along the rows of the DynamicTable and each step along the first dimension is a cell of the larger table. VectorData can also be used to represent a ragged array if paired with a VectorIndex. This allows for storing arrays of varying length in a single cell of the DynamicTable by indexing into this VectorData. The first vector is at VectorData[0:VectorIndex[0]]. The second vector is at VectorData[VectorIndex[0]:VectorIndex[1]], and so on.


% HIDDEN READONLY PROPERTIES
properties(Hidden, SetAccess = protected)
    unit; %  (char) NOTE: this is a special value for compatibility with the Units table and is only written to file when detected to be in that specific HDF5 Group. The value must be 'volts'
end
% HIDDEN PROPERTIES
properties(Hidden)
    resolution; %  (double) NOTE: this is a special value for compatibility with the Units table and is only written to file when detected to be in that specific HDF5 Group. The smallest possible difference between two spike times. Usually 1 divided by the acquisition sampling rate from which spike times were extracted, but could be larger if the acquisition time series was downsampled or smaller if the acquisition time series was smoothed/interpolated and it is possible for the spike time to be between samples.
    sampling_rate; %  (single) NOTE: this is a special value for compatibility with the Units table and is only written to file when detected to be in that specific HDF5 Group. Must be Hertz
end
% OPTIONAL PROPERTIES
properties
    description; %  (char) Description of what these vectors represent.
end

methods
    function obj = VectorData(varargin)
        % VECTORDATA Constructor for VectorData
        varargin = [{'unit' 'volts'} varargin];
        obj = obj@types.hdmf_common.Data(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        addParameter(p, 'description',[]);
        addParameter(p, 'resolution',[]);
        addParameter(p, 'sampling_rate',[]);
        addParameter(p, 'unit',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        obj.description = p.Results.description;
        obj.resolution = p.Results.resolution;
        obj.sampling_rate = p.Results.sampling_rate;
        obj.unit = p.Results.unit;
        if strcmp(class(obj), 'types.hdmf_common.VectorData')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    function set.resolution(obj, val)
        obj.resolution = obj.validate_resolution(val);
    end
    function set.sampling_rate(obj, val)
        obj.sampling_rate = obj.validate_sampling_rate(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
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
    function val = validate_resolution(obj, val)
        val = types.util.checkDtype('resolution', 'double', val);
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
    function val = validate_sampling_rate(obj, val)
        val = types.util.checkDtype('sampling_rate', 'single', val);
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
        refs = export@types.hdmf_common.Data(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        io.writeAttribute(fid, [fullpath '/description'], obj.description);
        if ~isempty(obj.resolution) && any(endsWith(fullpath, 'units/spike_times'))
            io.writeAttribute(fid, [fullpath '/resolution'], obj.resolution);
        end
        validDataSamplingPaths = strcat('units/', {'waveform_mean', 'waveform_sd', 'waveforms'});
        if ~isempty(obj.sampling_rate) && any(endsWith(fullpath, validDataSamplingPaths))
            io.writeAttribute(fid, [fullpath '/sampling_rate'], obj.sampling_rate);
        end
        validUnitPaths = strcat('units/', {'waveform_mean', 'waveform_sd', 'waveforms'});
        if ~isempty(obj.unit) && any(endsWith(fullpath, validUnitPaths))
            io.writeAttribute(fid, [fullpath '/unit'], obj.unit);
        end
    end
end

end