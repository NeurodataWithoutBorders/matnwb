classdef VoltageClampSeries < types.PatchClampSeries

  properties
    capacitance_fast;
    capacitance_fast_unit;
    capacitance_slow;
    capacitance_slow_unit;
    resistance_comp_bandwidth;
    resistance_comp_bandwidth_unit;
    resistance_comp_correction;
    resistance_comp_correction_unit;
    resistance_comp_prediction;
    resistance_comp_prediction_unit;
    whole_cell_capacitance_comp;
    whole_cell_capacitance_comp_unit;
    whole_cell_series_resistance_comp;
    whole_cell_series_resistance_comp_unit;
  end

  methods %constructor
    function obj = VoltageClampSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('capacitance_fast', []);
      p.addParameter('capacitance_fast_unit', {'Farad'});
      p.addParameter('capacitance_slow', []);
      p.addParameter('capacitance_slow_unit', {'Farad'});
      p.addParameter('resistance_comp_bandwidth', []);
      p.addParameter('resistance_comp_bandwidth_unit', {'Hz'});
      p.addParameter('resistance_comp_correction', []);
      p.addParameter('resistance_comp_correction_unit', {'pecent'});
      p.addParameter('resistance_comp_prediction', []);
      p.addParameter('resistance_comp_prediction_unit', {'pecent'});
      p.addParameter('whole_cell_capacitance_comp', []);
      p.addParameter('whole_cell_capacitance_comp_unit', {'Farad'});
      p.addParameter('whole_cell_series_resistance_comp', []);
      p.addParameter('whole_cell_series_resistance_comp_unit', {'Ohm'});
      p.parse(varargin{:});
      obj = obj@types.PatchClampSeries(varargin{:});
      obj.help = {'Current recorded from cell during voltage-clamp recording'};
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
      export@types.PatchClampSeries(obj, loc_id);
      if ~isempty(obj.capacitance_fast)
        id = h5util.writeDataset(loc_id, 'capacitance_fast', obj.capacitance_fast, 'single');
        h5util.writeAttribute(id, 'unit', obj.capacitance_fast_unit, 'string');
        H5D.close(id);
      end
      if ~isempty(obj.capacitance_slow)
        id = h5util.writeDataset(loc_id, 'capacitance_slow', obj.capacitance_slow, 'single');
        h5util.writeAttribute(id, 'unit', obj.capacitance_slow_unit, 'string');
        H5D.close(id);
      end
      if ~isempty(obj.resistance_comp_bandwidth)
        id = h5util.writeDataset(loc_id, 'resistance_comp_bandwidth', obj.resistance_comp_bandwidth, 'single');
        h5util.writeAttribute(id, 'unit', obj.resistance_comp_bandwidth_unit, 'string');
        H5D.close(id);
      end
      if ~isempty(obj.resistance_comp_correction)
        id = h5util.writeDataset(loc_id, 'resistance_comp_correction', obj.resistance_comp_correction, 'single');
        h5util.writeAttribute(id, 'unit', obj.resistance_comp_correction_unit, 'string');
        H5D.close(id);
      end
      if ~isempty(obj.resistance_comp_prediction)
        id = h5util.writeDataset(loc_id, 'resistance_comp_prediction', obj.resistance_comp_prediction, 'single');
        h5util.writeAttribute(id, 'unit', obj.resistance_comp_prediction_unit, 'string');
        H5D.close(id);
      end
      if ~isempty(obj.whole_cell_capacitance_comp)
        id = h5util.writeDataset(loc_id, 'whole_cell_capacitance_comp', obj.whole_cell_capacitance_comp, 'single');
        h5util.writeAttribute(id, 'unit', obj.whole_cell_capacitance_comp_unit, 'string');
        H5D.close(id);
      end
      if ~isempty(obj.whole_cell_series_resistance_comp)
        id = h5util.writeDataset(loc_id, 'whole_cell_series_resistance_comp', obj.whole_cell_series_resistance_comp, 'single');
        h5util.writeAttribute(id, 'unit', obj.whole_cell_series_resistance_comp_unit, 'string');
        H5D.close(id);
      end
    end
  end
end