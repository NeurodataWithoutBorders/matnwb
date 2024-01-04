classdef TwoPhotonSeries < types.core.ImageSeries & types.untyped.GroupClass
% TWOPHOTONSERIES Image stack recorded over time from 2-photon microscope.


% OPTIONAL PROPERTIES
properties
    field_of_view; %  (single) Width, height and depth of image, or imaged area, in meters.
    imaging_plane; %  ImagingPlane
    pmt_gain; %  (single) Photomultiplier gain.
    scan_line_rate; %  (single) Lines imaged per second. This is also stored in /general/optophysiology but is kept here as it is useful information for analysis, and so good to be stored w/ the actual data.
end

methods
    function obj = TwoPhotonSeries(varargin)
        % TWOPHOTONSERIES Constructor for TwoPhotonSeries
        obj = obj@types.core.ImageSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'field_of_view',[]);
        addParameter(p, 'imaging_plane',[]);
        addParameter(p, 'pmt_gain',[]);
        addParameter(p, 'scan_line_rate',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.field_of_view = p.Results.field_of_view;
        obj.imaging_plane = p.Results.imaging_plane;
        obj.pmt_gain = p.Results.pmt_gain;
        obj.scan_line_rate = p.Results.scan_line_rate;
        if strcmp(class(obj), 'types.core.TwoPhotonSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.field_of_view(obj, val)
        obj.field_of_view = obj.validate_field_of_view(val);
    end
    function set.imaging_plane(obj, val)
        obj.imaging_plane = obj.validate_imaging_plane(val);
    end
    function set.pmt_gain(obj, val)
        obj.pmt_gain = obj.validate_pmt_gain(val);
    end
    function set.scan_line_rate(obj, val)
        obj.scan_line_rate = obj.validate_scan_line_rate(val);
    end
    %% VALIDATORS
    
    function val = validate_field_of_view(obj, val)
        val = types.util.checkDtype('field_of_view', 'single', val);
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
        validshapes = {[3], [2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_imaging_plane(obj, val)
        val = types.util.checkDtype('imaging_plane', 'types.core.ImagingPlane', val);
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
        if ~isempty(obj.field_of_view)
            if startsWith(class(obj.field_of_view), 'types.untyped.')
                refs = obj.field_of_view.export(fid, [fullpath '/field_of_view'], refs);
            elseif ~isempty(obj.field_of_view)
                io.writeDataset(fid, [fullpath '/field_of_view'], obj.field_of_view, 'forceArray');
            end
        end
        refs = obj.imaging_plane.export(fid, [fullpath '/imaging_plane'], refs);
        if ~isempty(obj.pmt_gain)
            io.writeAttribute(fid, [fullpath '/pmt_gain'], obj.pmt_gain);
        end
        if ~isempty(obj.scan_line_rate)
            io.writeAttribute(fid, [fullpath '/scan_line_rate'], obj.scan_line_rate);
        end
    end
end

end