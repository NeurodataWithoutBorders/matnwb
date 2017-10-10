classdef AbstractFeatureSeries < types.TimeSeries

  properties
    feature_units;
    features;
  end

  methods %constructor
    function obj = AbstractFeatureSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('feature_units', {});
      p.addParameter('features', {});
      p.parse(varargin{:});
      obj = obj@types.TimeSeries(varargin{:});
      obj.help = {'Features of an applied stimulus. This is useful when storing the raw stimulus is impractical'};
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
      if ~isempty(obj.feature_units)
        h5util.writeDataset(loc_id, 'feature_units', obj.feature_units, 'string');
      end
      h5util.writeDataset(loc_id, 'features', obj.features, 'string');
    end
  end
end