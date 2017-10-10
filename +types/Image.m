classdef Image < dynamicprops

  properties
    description;
    format;
  end

  methods %constructor
    function obj = Image(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('description', {});
      p.addParameter('format', {});
      p.parse(varargin{:});
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
      h5util.writeAttribute(loc_id, 'description', obj.description, 'string');
      h5util.writeAttribute(loc_id, 'format', obj.format, 'string');
    end
  end
end