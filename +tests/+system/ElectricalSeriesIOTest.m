classdef ElectricalSeriesIOTest < tests.system.PyNWBIOTest
  methods(Test)  
    function testOutToPyNWB(testCase)
      testCase.assumeFail(['Current schema in MatNWB does not include a ElectrodeTable class used by Python tests. ', ...
        'When it does, addContainer in this test will need to be updated to match the Python test']);
    end
    
    function testInFromPyNWB(testCase)
      testCase.assumeFail(['Current schema in MatNWB does not include a ElectrodeTable class used by Python tests. ', ...
        'When it does, addContainer in this test will need to be updated to match the Python test']);
    end
  end
  
  methods
    function addContainer(testCase, file) %#ok<INUSL>
      dev = types.Device( ...
        'source', {'a test source'});
      file.general.devices = types.untyped.Group();
      file.general.devices.dev1 = dev;
      eg = types.ElectrodeGroup( ...
        'source', {'a test source'}, ...
        'description', {'tetrode description'}, ...
        'location', {'tetrode location'}, ...
        'device', types.untyped.Link('/general/devices/dev1', '', dev));
      file.general.extracellular_ephys = types.untyped.Group();
      file.general.extracellular_ephys.tetrode1 = eg;
      es = types.ElectricalSeries( ...
        'source', {'a hypothetical source'}, ...
        'data', int32([0:9;10:19])', ...
        'electrode_group', types.untyped.Link('/general/extracellular_ephys/tetrode1', '', eg), ...
        'timestamps', (0:9)');
      file.acquisition.timeseries = types.untyped.Group();
      file.acquisition.timeseries.test_eS = es;
    end
    
    function c = getContainer(testCase, file) %#ok<INUSL>
      c = file.acquisition.timeseries.test_eS;
    end
  end
end

