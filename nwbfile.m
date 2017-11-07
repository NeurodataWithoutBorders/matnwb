classdef nwbfile < types.NWBFile
  % nwbfile Root object representing data read from an NWB file.
  %
  % Requires that core and extension NWB types have been generated
  % and reside in a 'types' package on the matlab path.
  %
  % Example. Construct an object from scratch for export:
  %    nwb = nwbfile;
  %    nwb.epochs = types.untyped.Group;
  %    nwb.epochs.stim = types.Epoch;
  %    nwbExport(nwb, 'epoch.nwb');
  %
  % See also NWBREAD, GENERATECORE, GENERATEEXTENSIONS
  methods
    function obj = nwbfile(varargin)
      obj = obj@types.NWBFile(varargin{:});
    end
    
    function ref = getFromPath(obj, path)
      ref = obj(path);
    end
    
    function varargout = subsref(obj, s)
      ref = obj;
      if any(strcmp(s(1).type, {'{}', '()'}))
        sub = s(1).subs{1};%only grab the first
        for token=parsePath(obj, sub)'
          ref = ref.(token{1});
          if isa(ref, 'types.untyped.Link') %automatically dereference links
            ref = ref.ref;
          end
        end
        if length(s) > 1
          ref = subsref(ref, s(2:end));
        end
        varargout{1} = ref;
      else
        [varargout{1:nargout}] = builtin('subsref', obj, s);
      end
    end
    
    function export(obj, filename)
      validateattributes(filename, {'string', 'char'}, {'scalartext'});
      if exist(filename, 'file')
        warning('Overwriting %s', filename);
        delete(filename);
      end
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