classdef EventDetection < types.NWBContainer

  properties
    detection_method;
    source_electricalseries;
    source_idx;
    times;
    times_unit;
  end

  methods %constructor
    function obj = EventDetection(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('detection_method', {});
      p.addParameter('source_idx', []);
      p.addParameter('times', []);
      p.addParameter('times_unit', {'Seconds'});
      p.addParameter('source_electricalseries', []);
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'Detected spike events from voltage trace(s)'};
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
      h5util.writeDataset(loc_id, 'detection_method', obj.detection_method, 'string');
      h5util.writeDataset(loc_id, 'source_idx', obj.source_idx, 'int32');
      id = h5util.writeDataset(loc_id, 'times', obj.times, 'double');
      h5util.writeAttribute(id, 'unit', obj.times_unit, 'string');
      H5D.close(id);
      export(obj.source_electricalseries, loc_id, 'source_electricalseries');
    end
  end
end