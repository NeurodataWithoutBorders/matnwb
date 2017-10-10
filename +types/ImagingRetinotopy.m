classdef ImagingRetinotopy < types.NWBContainer

  properties
    axis_1_phase_map;
    axis_1_phase_map_dimension;
    axis_1_phase_map_field_of_view;
    axis_1_phase_map_unit;
    axis_1_power_map;
    axis_1_power_map_dimension;
    axis_1_power_map_field_of_view;
    axis_1_power_map_unit;
    axis_2_phase_map;
    axis_2_phase_map_dimension;
    axis_2_phase_map_field_of_view;
    axis_2_phase_map_unit;
    axis_2_power_map;
    axis_2_power_map_dimension;
    axis_2_power_map_field_of_view;
    axis_2_power_map_unit;
    axis_descriptions;
    focal_depth_image;
    focal_depth_image_bits_per_pixel;
    focal_depth_image_dimension;
    focal_depth_image_field_of_view;
    focal_depth_image_focal_depth;
    focal_depth_image_format;
    sign_map;
    sign_map_dimension;
    sign_map_field_of_view;
    vasculature_image;
    vasculature_image_bits_per_pixel;
    vasculature_image_dimension;
    vasculature_image_field_of_view;
    vasculature_image_format;
  end

  methods %constructor
    function obj = ImagingRetinotopy(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('axis_1_phase_map', []);
      p.addParameter('axis_1_phase_map_dimension', []);
      p.addParameter('axis_1_phase_map_field_of_view', []);
      p.addParameter('axis_1_phase_map_unit', {});
      p.addParameter('axis_1_power_map', []);
      p.addParameter('axis_1_power_map_dimension', []);
      p.addParameter('axis_1_power_map_field_of_view', []);
      p.addParameter('axis_1_power_map_unit', {});
      p.addParameter('axis_2_phase_map', []);
      p.addParameter('axis_2_phase_map_dimension', []);
      p.addParameter('axis_2_phase_map_field_of_view', []);
      p.addParameter('axis_2_phase_map_unit', {});
      p.addParameter('axis_2_power_map', []);
      p.addParameter('axis_2_power_map_dimension', []);
      p.addParameter('axis_2_power_map_field_of_view', []);
      p.addParameter('axis_2_power_map_unit', {});
      p.addParameter('axis_descriptions', {});
      p.addParameter('focal_depth_image', []);
      p.addParameter('focal_depth_image_bits_per_pixel', []);
      p.addParameter('focal_depth_image_dimension', []);
      p.addParameter('focal_depth_image_field_of_view', []);
      p.addParameter('focal_depth_image_focal_depth', []);
      p.addParameter('focal_depth_image_format', {});
      p.addParameter('sign_map', []);
      p.addParameter('sign_map_dimension', []);
      p.addParameter('sign_map_field_of_view', []);
      p.addParameter('vasculature_image', []);
      p.addParameter('vasculature_image_bits_per_pixel', []);
      p.addParameter('vasculature_image_dimension', []);
      p.addParameter('vasculature_image_field_of_view', []);
      p.addParameter('vasculature_image_format', {});
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'Intrinsic signal optical imaging or Widefield imaging for measuring retinotopy'};
      fn = fieldnames(p.Results);
      if ~isempty(fn)
        for i=1:length(fn)
          field = fn{i};
          obj.(field) = p.Results.(field);
        end
      end
    end
  end

  methods %setters
  end

  methods(Access=protected) %validators
  end

  methods  %export
    function export(obj, loc_id)
      export@types.NWBContainer(obj, loc_id);
      id = h5util.writeDataset(loc_id, 'axis_1_phase_map', obj.axis_1_phase_map, 'single');
      h5util.writeAttribute(id, 'dimension', obj.axis_1_phase_map_dimension, 'int32');
      h5util.writeAttribute(id, 'field_of_view', obj.axis_1_phase_map_field_of_view, 'double');
      h5util.writeAttribute(id, 'unit', obj.axis_1_phase_map_unit, 'string');
      H5D.close(id);
      if ~isempty(obj.axis_1_power_map)
        id = h5util.writeDataset(loc_id, 'axis_1_power_map', obj.axis_1_power_map, 'single');
        h5util.writeAttribute(id, 'dimension', obj.axis_1_power_map_dimension, 'int32');
        h5util.writeAttribute(id, 'field_of_view', obj.axis_1_power_map_field_of_view, 'double');
        h5util.writeAttribute(id, 'unit', obj.axis_1_power_map_unit, 'string');
        H5D.close(id);
      end
      id = h5util.writeDataset(loc_id, 'axis_2_phase_map', obj.axis_2_phase_map, 'single');
      h5util.writeAttribute(id, 'dimension', obj.axis_2_phase_map_dimension, 'int32');
      h5util.writeAttribute(id, 'field_of_view', obj.axis_2_phase_map_field_of_view, 'double');
      h5util.writeAttribute(id, 'unit', obj.axis_2_phase_map_unit, 'string');
      H5D.close(id);
      if ~isempty(obj.axis_2_power_map)
        id = h5util.writeDataset(loc_id, 'axis_2_power_map', obj.axis_2_power_map, 'single');
        h5util.writeAttribute(id, 'dimension', obj.axis_2_power_map_dimension, 'int32');
        h5util.writeAttribute(id, 'field_of_view', obj.axis_2_power_map_field_of_view, 'double');
        h5util.writeAttribute(id, 'unit', obj.axis_2_power_map_unit, 'string');
        H5D.close(id);
      end
      h5util.writeDataset(loc_id, 'axis_descriptions', obj.axis_descriptions, 'string');
      id = h5util.writeDataset(loc_id, 'focal_depth_image', obj.focal_depth_image, 'uint16');
      h5util.writeAttribute(id, 'bits_per_pixel', obj.focal_depth_image_bits_per_pixel, 'int32');
      h5util.writeAttribute(id, 'dimension', obj.focal_depth_image_dimension, 'int32');
      h5util.writeAttribute(id, 'field_of_view', obj.focal_depth_image_field_of_view, 'double');
      h5util.writeAttribute(id, 'focal_depth', obj.focal_depth_image_focal_depth, 'double');
      h5util.writeAttribute(id, 'format', obj.focal_depth_image_format, 'string');
      H5D.close(id);
      id = h5util.writeDataset(loc_id, 'sign_map', obj.sign_map, 'single');
      h5util.writeAttribute(id, 'dimension', obj.sign_map_dimension, 'int32');
      h5util.writeAttribute(id, 'field_of_view', obj.sign_map_field_of_view, 'double');
      H5D.close(id);
      id = h5util.writeDataset(loc_id, 'vasculature_image', obj.vasculature_image, 'uint16');
      h5util.writeAttribute(id, 'bits_per_pixel', obj.vasculature_image_bits_per_pixel, 'int32');
      h5util.writeAttribute(id, 'dimension', obj.vasculature_image_dimension, 'int32');
      h5util.writeAttribute(id, 'field_of_view', obj.vasculature_image_field_of_view, 'double');
      h5util.writeAttribute(id, 'format', obj.vasculature_image_format, 'string');
      H5D.close(id);
    end
  end
end