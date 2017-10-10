classdef ElectricalSeries < types.TimeSeries

  properties
    electrode_group;
  end

  methods %constructor
    function obj = ElectricalSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('electrode_group', []);
      p.parse(varargin{:});
      obj = obj@types.TimeSeries(varargin{:});
      obj.help = {'Stores acquired voltage data from extracellular recordings'};
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
      export@types.TimeSeries(obj, loc_id);
      export(obj.electrode_group, loc_id, 'electrode_group');
    end
  end
end