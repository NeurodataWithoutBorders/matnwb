classdef Epoch < types.NWBContainer
  properties %datasets
    description;
    start_time;
    stop_time;
    tags;
  end
  
  methods
    function obj = Epoch(varargin)
      p = inputParser;
      p.addParameter('description', {});
      p.addParameter('start_time', []);
      p.addParameter('stop_time', []);
      p.addParameter('tags', {});
      p.addParameter('groups', struct()); %for all groups
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'A general epoch object'};
      
      %optional for unnamed groups
      %group structure should be
      % group.
      %   <name>.
      %     <Type|Group> *noted by presence of neurodata_type attribute
      %   .
      %   .
      %   .
      gn = fieldnameS(p.Results.groups);
      if ~isempty(gn)
        for i=1:length(gn)
          %check for groups satisfying some property/quantity
          %so for epoch we check only for one group with some number (or none)
          %of a particular type EpochTimeSeries
          gnm = gn{i};
          if isfield(obj, gnm)
            error('Naming conflict found in Epoch object property name: ''%s''', gnm);
          else
            obj.(gnm) = p.Results.groups.(gnm);
          end
        end
      end
      p.Results = rmfield(p.Results, 'groups'); %groups should not be a property
      
      fn = fieldnames(p.Results);
      if ~isempty(fn)
        for i=1:length(fn)
          field = fn{i};
          obj.(field) = p.Results.(field);
        end
      end
    end
  end
    
  methods
    function set.description(obj, val)
      obj.validate_description(val);
      obj.description = val;
    end
    
    function set.start_time(obj, val)
      obj.validate_start_time(val);
      obj.start_time = val;
    end
    
    function set.stop_time(obj, val)
      obj.validate_stop_time(val);
      obj.stop_time = val;
    end
    
    function set.tags(obj, val)
      obj.validate_tags(val);
      obj.tags = val;
    end
  end
  
  methods(Access=protected)
    function validate_description(~, val)
      validateattributes(val, {'string', 'char'}, {'scalartext'});
    end
    
    function validate_start_time(~, val)
      validateattributes(val, {'double'}, {'scalar'});
    end
    
    function validate_stop_time(~, val)
      validateattributes(val, {'double'}, {'scalar'});
    end
    
    function validate_tags(~, val)
      validateattributes(val, {'string', 'cell'}, {'vector'});
      if iscell(val) && ~iscellstr(val)
        error('Epoch tags should be string array or cellstr array');
      end
    end
  end
  
  methods %export
    function export(obj, loc_id)
      export@types.NWBContainer(obj, loc_id);
      
      if ~isempty(obj.description)
        h5util.writeDataset(loc_id, 'description', obj.description);
      end
      
      h5util.writeDataset(loc_id, 'start_time', obj.start_time);
      h5util.writeDataset(loc_id, 'stop_time', obj.stop_time);
      
      %Classes with unnamed groups.
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