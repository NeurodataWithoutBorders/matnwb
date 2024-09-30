classdef OnePhotonSeries < types.core.ImageSeries & types.untyped.GroupClass
% ONEPHOTONSERIES Image stack recorded over time from 1-photon microscope.


% OPTIONAL PROPERTIES
properties
    binning; %  (uint8) Amount of pixels combined into 'bins'; could be 1, 2, 4, 8, etc.
    exposure_time; %  (single) Exposure time of the sample; often the inverse of the frequency.
    imaging_plane; %  ImagingPlane
    intensity; %  (single) Intensity of the excitation in mW/mm^2, if known.
    pmt_gain; %  (single) Photomultiplier gain.
    power; %  (single) Power of the excitation in mW, if known.
    scan_line_rate; %  (single) Lines imaged per second. This is also stored in /general/optophysiology but is kept here as it is useful information for analysis, and so good to be stored w/ the actual data.
end

methods
    function obj = OnePhotonSeries(varargin)
        % ONEPHOTONSERIES Constructor for OnePhotonSeries
        obj = obj@types.core.ImageSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'binning',[]);
        addParameter(p, 'exposure_time',[]);
        addParameter(p, 'imaging_plane',[]);
        addParameter(p, 'intensity',[]);
        addParameter(p, 'pmt_gain',[]);
        addParameter(p, 'power',[]);
        addParameter(p, 'scan_line_rate',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.binning = p.Results.binning;
        obj.exposure_time = p.Results.exposure_time;
        obj.imaging_plane = p.Results.imaging_plane;
        obj.intensity = p.Results.intensity;
        obj.pmt_gain = p.Results.pmt_gain;
        obj.power = p.Results.power;
        obj.scan_line_rate = p.Results.scan_line_rate;
        if strcmp(class(obj), 'types.core.OnePhotonSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.binning(obj, val)
        obj.binning = obj.validate_binning(val);
    end
    function set.exposure_time(obj, val)
        obj.exposure_time = obj.validate_exposure_time(val);
    end
    function set.imaging_plane(obj, val)
        obj.imaging_plane = obj.validate_imaging_plane(val);
    end
    function set.intensity(obj, val)
        obj.intensity = obj.validate_intensity(val);
    end
    function set.pmt_gain(obj, val)
        obj.pmt_gain = obj.validate_pmt_gain(val);
    end
    function set.power(obj, val)
        obj.power = obj.validate_power(val);
    end
    function set.scan_line_rate(obj, val)
        obj.scan_line_rate = obj.validate_scan_line_rate(val);
    end
    %% VALIDATORS
    
    function val = validate_binning(obj, val)
        val = types.util.checkDtype('binning', 'uint8', val);
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
    function val = validate_exposure_time(obj, val)
        val = types.util.checkDtype('exposure_time', 'single', val);
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
    function val = validate_imaging_plane(obj, val)
        val = types.util.checkDtype('imaging_plane', 'types.core.ImagingPlane', val);
    end
    function val = validate_intensity(obj, val)
        val = types.util.checkDtype('intensity', 'single', val);
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
    function val = validate_pmt_gain(obj, val)
        val = types.util.checkDtype('pmt_gain', 'single', val);
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
    function val = validate_power(obj, val)
        val = types.util.checkDtype('power', 'single', val);
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
    function val = validate_scan_line_rate(obj, val)
        val = types.util.checkDtype('scan_line_rate', 'single', val);
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
        refs = export@types.core.ImageSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.binning)
            io.writeAttribute(fid, [fullpath '/binning'], obj.binning);
        end
        if ~isempty(obj.exposure_time)
            io.writeAttribute(fid, [fullpath '/exposure_time'], obj.exposure_time);
        end
        refs = obj.imaging_plane.export(fid, [fullpath '/imaging_plane'], refs);
        if ~isempty(obj.intensity)
            io.writeAttribute(fid, [fullpath '/intensity'], obj.intensity);
        end
        if ~isempty(obj.pmt_gain)
            io.writeAttribute(fid, [fullpath '/pmt_gain'], obj.pmt_gain);
        end
        if ~isempty(obj.power)
            io.writeAttribute(fid, [fullpath '/power'], obj.power);
        end
        if ~isempty(obj.scan_line_rate)
            io.writeAttribute(fid, [fullpath '/scan_line_rate'], obj.scan_line_rate);
        end
    end
end

end