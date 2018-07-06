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
            dev = types.core.Device( ...
                'source', 'a test source');
            file.general_devices.set('dev1', dev);
            eg = types.core.ElectrodeGroup( ...
                'source', 'a test source', ...
                'description', 'tetrode description', ...
                'location', 'tetrode location', ...
                'device', types.untyped.SoftLink('/general/devices/dev1'));
            file.general_extracellular_ephys.set('tetrode1', eg);
            es = types.core.ElectricalSeries( ...
                'source', 'a hypothetical source', ...
                'data', int32([0:9;10:19]) .', ...
                'electrode_group', types.untyped.SoftLink('/general/extracellular_ephys/tetrode1'), ...
                'timestamps', (0:9) .');
            etr = types.core.ElectrodeTableRegion;
            es.electrodes = etr;
            file.acquisition.set('test_eS', es);
        end
        
        function c = getContainer(testCase, file) %#ok<INUSL>
            c = file.acquisition.get('test_eS');
        end
    end
end

