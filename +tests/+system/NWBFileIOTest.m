classdef NWBFileIOTest < tests.system.PyNWBIOTest
  methods    
    function addContainer(testCase, file) %#ok<INUSL>
      ts = types.TimeSeries( ...
        'source', {'example_source'}, ...
        'data', int32(100:10:190)', ...
        'data_unit', {'SIunit'}, ...
        'timestamps', (0:9)', ...
        'data_resolution', 0.1);
      file.acquisition.timeseries = types.untyped.Group();
      file.acquisition.timeseries.test_timeseries = ts;
      clust = types.Clustering( ...
        'source', {'an example source for Clustering'}, ...
        'description', {'A fake Clustering interface'}, ...
        'num', [0, 1, 2, 0, 1, 2]', ...
        'peak_over_rms', [100, 101, 102]', ...
        'times', (10:10:60)');
      mod = types.ProcessingModule( ...
        'source', {'a test source for a ProcessingModule'}, ...
        'description', {'a test module'}, ...
        'groups', struct('Clustering', clust));
      file.processing.test_module = mod;
    end
    
    function c = getContainer(testCase, file) %#ok<INUSL>
      c = file;
    end
  end
end

