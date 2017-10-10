classdef NWBFile < types.NWBContainer

  properties
    file_create_date;
    identifier;
    nwb_version;
    session_description;
    session_start_time;
  end

  methods %constructor
    function obj = NWBFile(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('file_create_date', {});
      p.addParameter('identifier', {});
      p.addParameter('nwb_version', {});
      p.addParameter('session_description', {});
      p.addParameter('session_start_time', {});
      p.addParameter('groups', struct());
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'an NWB:N file for storing cellular-based neurophysiology data'};
      fn = fieldnames(p.Results);
      if ~isempty(fn)
        for i=1:length(fn)
          field = fn{i};
          if ~strcmp(field, 'groups')
            obj.(field) = p.Results.(field);
          end
        end
      end
      gn = fieldnames(p.Results.groups);
      if ~isempty(gn)
        for i=1:length(gn)
          gnm = gn{i};
          if isfield(obj, gnm)
            error('Naming conflict found in NWBFile object property name: ''%s''', gnm);
          else
            addprop(obj, gnm);
            obj.(gnm) = p.Results.groups.(gnm);
          end
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
      h5util.writeDataset(loc_id, 'file_create_date', obj.file_create_date, 'string');
      h5util.writeDataset(loc_id, 'identifier', obj.identifier, 'string');
      h5util.writeDataset(loc_id, 'nwb_version', obj.nwb_version, 'string');
      h5util.writeDataset(loc_id, 'session_description', obj.session_description, 'string');
      h5util.writeDataset(loc_id, 'session_start_time', obj.session_start_time, 'string');
      plist = 'H5P_DEFAULT';
      fnms = fieldnames(obj);
      for i=1:length(fnms)
        fnm = fnms{i};
        if isa(fnm, 'Group')
          gid = H5G.create(loc_id, fnm, plist, plist, plist);
          export(obj.(fnm), gid);
          H5G.close(gid);
        end
      end
    end
  end
end