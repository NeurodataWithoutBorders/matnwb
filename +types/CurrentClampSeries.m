classdef CurrentClampSeries < types.PatchClampSeries

  properties
    bias_current;
    bridge_balance;
    capacitance_compensation;
  end

  methods %constructor
    function obj = CurrentClampSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('bias_current', []);
      p.addParameter('bridge_balance', []);
      p.addParameter('capacitance_compensation', []);
      p.parse(varargin{:});
      obj = obj@types.PatchClampSeries(varargin{:});
      obj.help = {'Voltage recorded from cell during current-clamp recording'};
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
      if ~isempty(obj.bias_current)
        h5util.writeDataset(loc_id, 'bias_current', obj.bias_current, 'single');
      end
      if ~isempty(obj.bridge_balance)
        h5util.writeDataset(loc_id, 'bridge_balance', obj.bridge_balance, 'single');
      end
      if ~isempty(obj.capacitance_compensation)
        h5util.writeDataset(loc_id, 'capacitance_compensation', obj.capacitance_compensation, 'single');
      end
    end
  end
end