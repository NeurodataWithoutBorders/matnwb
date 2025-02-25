classdef DatasetConfigurationTest < matlab.unittest.TestCase
% Tests for io.config.applyDatasetConfiguration function
    
    properties
        DefaultConfig
    end
    
    methods(TestMethodSetup)
        function setup(testCase)
            % Setup default configuration before each test
            testCase.DefaultConfig = io.config.readDatasetConfiguration();
        end
    end
    
    methods(Test)
        function testBasicFunctionality(testCase)
            % Test basic functionality with default configuration
            nwbFile = NwbFile( ...
                'identifier', 'TEST123', ...
                'session_description', 'test session', ...
                'session_start_time', datetime());
            
            % Should not throw any errors
            io.config.applyDatasetConfiguration(nwbFile, testCase.DefaultConfig);
        end
        
        function testNumericDatasetConfiguration(testCase)
            % Test configuration of numeric datasets
            nwbFile = NwbFile( ...
                'identifier', 'TEST123', ...
                'session_description', 'test session', ...
                'session_start_time', datetime());
            
            % Create a large numeric dataset
            data = types.core.TimeSeries( ...
                'data', rand(1000, 1000), ...
                'data_unit', 'n/a', ...
                'timestamps', 1:1000);
            
            nwbFile.acquisition.set('test_data', data);
            
            % Apply configuration
            io.config.applyDatasetConfiguration(nwbFile, testCase.DefaultConfig);
            
            % Verify the dataset was converted to DataPipe
            testCase.verifyTrue(isa(nwbFile.acquisition.get('test_data').data, ...
                'types.untyped.DataPipe'), ...
                'Large numeric dataset should be converted to DataPipe');
        end
        
        function testSmallNumericDataset(testCase)
            % Test that small numeric datasets remain unchanged
            nwbFile = NwbFile( ...
                'identifier', 'TEST123', ...
                'session_description', 'test session', ...
                'session_start_time', datetime());
            
            % Create a small numeric dataset
            data = types.core.TimeSeries( ...
                'data', rand(10, 10), ...
                'data_unit', 'n/a', ...
                'timestamps', 1:10);
            
            nwbFile.acquisition.set('test_data', data);
            
            % Apply configuration
            io.config.applyDatasetConfiguration(nwbFile, testCase.DefaultConfig);
            
            % Verify the dataset remains numeric
            testCase.verifyTrue(isnumeric(nwbFile.acquisition.get('test_data').data), ...
                'Small numeric dataset should remain numeric');
        end
        
        function testOverrideExisting(testCase)
            % Test override behavior for existing DataPipe objects
            nwbFile = NwbFile( ...
                'identifier', 'TEST123', ...
                'session_description', 'test session', ...
                'session_start_time', datetime());
            
            % Create a DataPipe object
            rawData = rand(1000, 1000);
            dataPipe = types.untyped.DataPipe('data', rawData, 'axis', 1, 'chunkSize', 100);
            
            data = types.core.TimeSeries( ...
                'data', dataPipe, ...
                'data_unit', 'n/a', ...
                'timestamps', 1:1000);
            
            nwbFile.acquisition.set('test_data', data);
            
            % Apply configuration with override
            io.config.applyDatasetConfiguration(nwbFile, testCase.DefaultConfig, ...
                'OverrideExisting', true);
            
            % Verify the DataPipe was reconfigured
            resultPipe = nwbFile.acquisition.get('test_data').data;
            testCase.verifyTrue(isa(resultPipe, 'types.untyped.DataPipe'), ...
                'Result should still be a DataPipe');
        end
        
        function testNoOverrideExisting(testCase)
            % Test that existing DataPipe objects are not modified without override
            nwbFile = NwbFile( ...
                'identifier', 'TEST123', ...
                'session_description', 'test session', ...
                'session_start_time', datetime());
            
            % Create a DataPipe object with specific configuration
            rawData = rand(1000, 1000);
            originalChunkSize = [100, 100];
            dataPipe = types.untyped.DataPipe('data', rawData, 'axis', 1, ...
                'chunkSize', originalChunkSize);
            
            data = types.core.TimeSeries( ...
                'data', dataPipe, ...
                'data_unit', 'n/a', ...
                'timestamps', 1:1000);
            
            nwbFile.acquisition.set('test_data', data);
            
            % Apply configuration without override
            io.config.applyDatasetConfiguration(nwbFile, testCase.DefaultConfig, ...
                'OverrideExisting', false);
            
            % Verify the DataPipe configuration remains unchanged
            resultPipe = nwbFile.acquisition.get('test_data').data;
            testCase.verifyEqual(resultPipe.chunkSize, originalChunkSize, ...
                'DataPipe configuration should remain unchanged without override');
        end
    end
end
