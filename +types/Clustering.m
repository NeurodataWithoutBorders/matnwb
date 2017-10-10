classdef Clustering < types.NWBContainer

  properties
    description;
    num;
    peak_over_rms;
    times;
  end

  methods %constructor
    function obj = Clustering(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('description', {});
      p.addParameter('num', []);
      p.addParameter('peak_over_rms', []);
      p.addParameter('times', []);
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'Clustered spike data, whether from automatic clustering tools (eg, klustakwik) or as a result of manual sorting'};
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
      h5util.writeDataset(loc_id, 'description', obj.description, 'string');
      h5util.writeDataset(loc_id, 'num', obj.num, 'int32');
      h5util.writeDataset(loc_id, 'peak_over_rms', obj.peak_over_rms, 'single');
      h5util.writeDataset(loc_id, 'times', obj.times, 'double');
    end
  end
end