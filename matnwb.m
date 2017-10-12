classdef matnwb < types.NWBFile
  methods
    function obj = matnwb(varargin)
      obj = obj@types.NWBFile(varargin{:});
    end
    
    function ref = getFromPath(obj, path)
      ref = obj(path);
    end
    
    function varargout = subsref(obj, s)
      switch s(1).type
        case {'()', '{}'}
          refs = cell(1, length(s(1).subs));
          for i=1:length(s(1).subs)
            sub = s(1).subs{i};
            
            ns = substruct('.', '');
            counter = 1;
            for token=parsePath(obj, sub)'
              ns(counter) = substruct('.', token{1});
              counter = counter + 1;
            end
            
            ref = subsref(obj, [ns s(2:end)]);
            refs{i} = ref;
          end
          varargout = refs;
        case '.'
          [varargout{1:nargout}] = builtin('subsref', obj, s);
      end
    end
    
    function export(obj, filename)
      validateattributes(filename, {'string', 'char'}, {'scalartext'});
      fid = H5F.create(filename);
      export@types.NWBFile(obj, fid);
      H5F.close(fid);
    end
  end
  methods(Access=private)
    function tok = parsePath(~, path)
      validateattributes(path, {'char', 'string'}, {'scalartext'});
      if startsWith(path, '/')
        splitidx = 2;
      else
        splitidx = 1;
      end
      tok = split(path(splitidx:end), '/');
    end
  end
end