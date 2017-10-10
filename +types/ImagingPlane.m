classdef ImagingPlane < types.NWBContainer

  properties
    description;
    device;
    excitation_lambda;
    imaging_rate;
    indicator;
    location;
    manifold;
    manifold_conversion;
    manifold_unit;
    reference_frame;
  end

  methods %constructor
    function obj = ImagingPlane(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('description', {});
      p.addParameter('device', {});
      p.addParameter('excitation_lambda', {});
      p.addParameter('imaging_rate', {});
      p.addParameter('indicator', {});
      p.addParameter('location', {});
      p.addParameter('manifold', []);
      p.addParameter('manifold_conversion', 1.0);
      p.addParameter('manifold_unit', {'Meter'});
      p.addParameter('reference_frame', {});
      p.addParameter('groups', struct());
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'Metadata about an imaging plane'};
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
            error('Naming conflict found in ImagingPlane object property name: ''%s''', gnm);
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
      if ~isempty(obj.description)
        h5util.writeDataset(loc_id, 'description', obj.description, 'string');
      end
      h5util.writeDataset(loc_id, 'device', obj.device, 'string');
      h5util.writeDataset(loc_id, 'excitation_lambda', obj.excitation_lambda, 'string');
      h5util.writeDataset(loc_id, 'imaging_rate', obj.imaging_rate, 'string');
      h5util.writeDataset(loc_id, 'indicator', obj.indicator, 'string');
      h5util.writeDataset(loc_id, 'location', obj.location, 'string');
      id = h5util.writeDataset(loc_id, 'manifold', obj.manifold, 'single');
      h5util.writeAttribute(id, 'conversion', obj.manifold_conversion, 'double');
      h5util.writeAttribute(id, 'unit', obj.manifold_unit, 'string');
      H5D.close(id);
      h5util.writeDataset(loc_id, 'reference_frame', obj.reference_frame, 'string');
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