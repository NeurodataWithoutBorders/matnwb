classdef Link < handle
  properties
    filename = '';
    path;
    ref;
  end
  
  methods
    function obj = Link(path, filename, ref)
      obj.path = path;
      if nargin > 1
        obj.filename = filename;
      end
      
      if nargin > 2
        obj.ref = ref;
      end
    end
    
    function export(obj, loc_id, nm)
      plist = 'H5P_DEFAULT';
      if isempty(obj.filename)
        H5L.create_soft(obj.path, loc_id, nm, plist, plist);
      else
        H5L.create_external(obj.filename, obj.path, loc_id, nm, plist, plist);
      end
    end
  end
end