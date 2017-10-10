classdef matnwb < types.NWBFile
  methods
    function obj = matnwb(varargin)
      obj = obj@types.NWBFile(varargin{:});
    end
    function ref = traverse(obj, path)
      validateattributes(path, {'char', 'string'}, {'scalartext'});
      if startsWith(path, '/')
        splitidx = 2;
      else
        splitidx = 1;
      end
      tokens = split(path(splitidx:end), '/');
      ref = obj;
      for i=length(tokens)
        tok = tokens{i};
        if isempty(tok)
          error('matnwb:traverse: invalid path, possible duplicate slash.');
        elseif ~isfield(ref, tok)
          error('matnwb:traverse: invalid path, property does not exist.');
        else
          ref = ref.(tok);
        end
      end
    end
  end
end