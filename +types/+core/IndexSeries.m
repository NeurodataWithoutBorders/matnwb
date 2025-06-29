classdef IndexSeries < types.core.TimeSeries & types.untyped.GroupClass
% INDEXSERIES - Stores indices that reference images defined in other containers. The primary purpose of the IndexSeries is to allow images stored in an Images container to be referenced in a specific sequence through the 'indexed_images' link. This approach avoids duplicating image data when the same image needs to be presented multiple times or when images need to be shown in a different order than they are stored. Since images in an Images container do not have an inherent order, the Images container needs to include an 'order_of_images' dataset (of type ImageReferences) when being referenced by an IndexSeries. This dataset establishes the ordered sequence that the indices in IndexSeries refer to. The 'data' field stores the index into this ordered sequence, and the 'timestamps' array indicates the precise presentation time of each indexed image during an experiment. This can be used for displaying individual images or creating movie segments by referencing a sequence of images with the appropriate timestamps. While IndexSeries can also reference frames from an ImageSeries through the 'indexed_timeseries' link, this usage is discouraged and will be deprecated in favor of using Images containers with 'order_of_images'.
%
% Required Properties:
%  data


% OPTIONAL PROPERTIES
properties
    indexed_images; %  Images
    indexed_timeseries; %  ImageSeries
end

methods
    function obj = IndexSeries(varargin)
        % INDEXSERIES - Constructor for IndexSeries
        %
        % Syntax:
        %  indexSeries = types.core.INDEXSERIES() creates a IndexSeries object with unset property values.
        %
        %  indexSeries = types.core.INDEXSERIES(Name, Value) creates a IndexSeries object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - comments (char) - Human-readable comments about the TimeSeries. This second descriptive field can be used to store additional information, or descriptive information if the primary description field is populated with a computer-readable string.
        %
        %  - control (uint8) - Numerical labels that apply to each time point in data for the purpose of querying and slicing data by these values. If present, the length of this array should be the same size as the first dimension of data.
        %
        %  - control_description (char) - Description of each control value. Must be present if control is present. If present, control_description[0] should describe time points where control == 0.
        %
        %  - data (uint32) - Index of the image (using zero-indexing) in the linked Images object.
        %
        %  - data_continuity (char) - Optionally describe the continuity of the data. Can be "continuous", "instantaneous", or "step". For example, a voltage trace would be "continuous", because samples are recorded from a continuous process. An array of lick times would be "instantaneous", because the data represents distinct moments in time. Times of image presentations would be "step" because the picture remains the same until the next timepoint. This field is optional, but is useful in providing information about the underlying data. It may inform the way this data is interpreted, the way it is visualized, and what analysis methods are applicable.
        %
        %  - data_conversion (single) - This field is unused by IndexSeries.
        %
        %  - data_offset (single) - This field is unused by IndexSeries.
        %
        %  - data_resolution (single) - This field is unused by IndexSeries.
        %
        %  - description (char) - Description of the time series.
        %
        %  - indexed_images (Images) - Link to Images object containing an ordered set of images that are indexed. The Images object must contain a 'ordered_images' dataset specifying the order of the images in the Images type.
        %
        %  - indexed_timeseries (ImageSeries) - Link to ImageSeries object containing images that are indexed. Use of this link is discouraged and will be deprecated. Link to an Images type instead.
        %
        %  - starting_time (double) - Timestamp of the first sample in seconds. When timestamps are uniformly spaced, the timestamp of the first sample can be specified and all subsequent ones calculated from the sampling rate attribute.
        %
        %  - starting_time_rate (single) - Sampling rate, in Hz.
        %
        %  - timestamps (double) - Timestamps for samples stored in data, in seconds, relative to the common experiment master-clock stored in NWBFile.timestamps_reference_time.
        %
        % Output Arguments:
        %  - indexSeries (types.core.IndexSeries) - A IndexSeries object
        
        varargin = [{'data_conversion' types.util.correctType(1, 'single') 'data_offset' types.util.correctType(0, 'single') 'data_resolution' types.util.correctType(-1, 'single') 'data_unit' 'N/A'} varargin];
        obj = obj@types.core.TimeSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'indexed_images',[]);
        addParameter(p, 'indexed_timeseries',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.indexed_images = p.Results.indexed_images;
        obj.indexed_timeseries = p.Results.indexed_timeseries;
        if strcmp(class(obj), 'types.core.IndexSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.indexed_images(obj, val)
        obj.indexed_images = obj.validate_indexed_images(val);
    end
    function set.indexed_timeseries(obj, val)
        obj.indexed_timeseries = obj.validate_indexed_timeseries(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'uint32', val);
        types.util.validateShape('data', {[Inf]}, val)
    end
    function val = validate_data_conversion(obj, val)
        val = types.util.checkDtype('data_conversion', 'single', val);
        types.util.validateShape('data_conversion', {[1]}, val)
    end
    function val = validate_data_offset(obj, val)
        val = types.util.checkDtype('data_offset', 'single', val);
        types.util.validateShape('data_offset', {[1]}, val)
    end
    function val = validate_data_resolution(obj, val)
        val = types.util.checkDtype('data_resolution', 'single', val);
        types.util.validateShape('data_resolution', {[1]}, val)
    end
    function val = validate_data_unit(obj, val)
        if isequal(val, 'N/A')
            val = 'N/A';
        else
            error('NWB:Type:ReadOnlyProperty', 'Unable to set the ''data_unit'' property of class ''<a href="matlab:doc types.core.IndexSeries">IndexSeries</a>'' because it is read-only.')
        end
    end
    function val = validate_indexed_images(obj, val)
        if isa(val, 'types.untyped.SoftLink')
            if isprop(val, 'target')
                types.util.checkDtype('indexed_images', 'types.core.Images', val.target);
            end
        else
            val = types.util.checkDtype('indexed_images', 'types.core.Images', val);
            if ~isempty(val)
                val = types.untyped.SoftLink(val);
            end
        end
    end
    function val = validate_indexed_timeseries(obj, val)
        if isa(val, 'types.untyped.SoftLink')
            if isprop(val, 'target')
                types.util.checkDtype('indexed_timeseries', 'types.core.ImageSeries', val.target);
            end
        else
            val = types.util.checkDtype('indexed_timeseries', 'types.core.ImageSeries', val);
            if ~isempty(val)
                val = types.untyped.SoftLink(val);
            end
        end
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.TimeSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.indexed_images)
            refs = obj.indexed_images.export(fid, [fullpath '/indexed_images'], refs);
        end
        if ~isempty(obj.indexed_timeseries)
            refs = obj.indexed_timeseries.export(fid, [fullpath '/indexed_timeseries'], refs);
        end
    end
end

end