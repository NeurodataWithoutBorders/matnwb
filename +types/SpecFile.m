classdef SpecFile < dynamicprops

  properties
    help;
    namespaces;
  end

  methods %constructor
    function obj = SpecFile(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('help', {'Contents of format specification file.'});
      p.addParameter('namespaces', {});
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
      h5util.writeAttribute(loc_id, 'help', obj.help, 'string');
      h5util.writeAttribute(loc_id, 'namespaces', obj.namespaces, 'string');
    end
  end
end