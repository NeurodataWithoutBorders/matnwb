classdef ClusterWaveforms < types.NWBContainer

  properties
    clustering_interface;
    waveform_filtering;
    waveform_mean;
    waveform_sd;
  end

  methods %constructor
    function obj = ClusterWaveforms(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('waveform_filtering', {});
      p.addParameter('waveform_mean', []);
      p.addParameter('waveform_sd', []);
      p.addParameter('clustering_interface', []);
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'Mean waveform shape of clusters. Waveforms should be high-pass filtered (ie, not the same bandpass filter used waveform analysis and clustering)'};
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
      export@types.NWBContainer(obj, loc_id);
      h5util.writeDataset(loc_id, 'waveform_filtering', obj.waveform_filtering, 'string');
      h5util.writeDataset(loc_id, 'waveform_mean', obj.waveform_mean, 'single');
      h5util.writeDataset(loc_id, 'waveform_sd', obj.waveform_sd, 'single');
      export(obj.clustering_interface, loc_id, 'clustering_interface');
    end
  end
end