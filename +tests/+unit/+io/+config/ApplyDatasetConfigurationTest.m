classdef ApplyDatasetConfigurationTest < tests.abstract.NwbTestCase
% Tests for io.config.applyDatasetConfiguration function
    
% Todo: 
%   [ ] Test configuration with a custom compression filter


    properties
        DefaultConfig
        CustomConfig
    end
    
    methods(TestMethodSetup)
        function setup(testCase)
            % Setup default and custom configurations before each test
            testCase.DefaultConfig = io.config.readDatasetConfiguration("cloud");
            
            % Create a custom configuration for testing
            testCase.CustomConfig = testCase.DefaultConfig;
            
            % Customize the configuration for specific neurodata types
            % Set a custom chunk dimension strategy for TimeSeries data
            testCase.CustomConfig.TimeSeries_data.chunking.strategy_by_rank.x2 = {10, 'flex'};
            
            % Set a custom compression filter
            testCase.CustomConfig.TimeSeries_data.compression.algorithm = 'ZStandard';
            testCase.CustomConfig.TimeSeries_data.compression.level = 5;
        end
    end
    
    methods(Test)
        function testCustomConfiguration(testCase)
            nwbFile = tests.factory.NWBFile();
            
            % Create a large TimeSeries dataset
            data = types.core.TimeSeries( ...
                'data', rand(64, 100000), ...
                'data_unit', 'n/a', ...
                'timestamps', 1:100000);
            
            nwbFile.acquisition.set('custom_chunked_data', data);
            
            % Apply custom configuration
            io.config.applyDatasetConfiguration(nwbFile, testCase.CustomConfig);
            
            % Verify the dataset was converted to DataPipe with custom chunk size
            resultPipe = nwbFile.acquisition.get('custom_chunked_data').data;
            testCase.verifyTrue(isa(resultPipe, 'types.untyped.DataPipe'), ...
                'Large dataset should be converted to DataPipe');
            
            % Verify the first dimension of chunk size is 10 as specified in custom config
            testCase.verifyEqual(resultPipe.chunkSize(1), 10, ...
                'First dimension of chunk size should match custom configuration');
        end

        function testVectorData(testCase)
            % Test Dataset-based neurodata type (VectorData)
            nwbFile = tests.factory.NWBFile();
            
            numTimePoints = 10000000;
            
            % Create VectorData objects with large datasets
            vdA = types.hdmf_common.VectorData(...
               'data', rand(1, numTimePoints));
            vdB = types.hdmf_common.VectorData(...
               'data', rand(1, numTimePoints));
            
            % Create a DynamicTable with the VectorData
            dt = types.hdmf_common.DynamicTable(...
                'description', 'test chunking columndata', ...
                'colnames', {'columnA', 'columnB'}, ...
                'columnA', vdA, ...
                'columnB', vdB);
            
            nwbFile.acquisition.set('VectorDataTable', dt);
            
            % Apply configuration
            io.config.applyDatasetConfiguration(nwbFile, testCase.DefaultConfig);
            
            % Verify the VectorData datasets were converted to DataPipe
            resultTable = nwbFile.acquisition.get('VectorDataTable');
            testCase.verifyTrue(isa(resultTable.vectordata.get('columnA').data, 'types.untyped.DataPipe'), ...
                'VectorData columnA should be converted to DataPipe');
            testCase.verifyTrue(isa(resultTable.vectordata.get('columnB').data, 'types.untyped.DataPipe'), ...
                'VectorData columnB should be converted to DataPipe');
        end
        
        function testChunkDimensionConstraints(testCase)
            % todo
            
            % Test all cases of chunk_dimension constraints
            nwbFile = tests.factory.NWBFile();
            
            % Create custom configurations for different chunk dimension specifications
            nullConfig = testCase.DefaultConfig;
            nullConfig.TimeSeries_data.chunking.strategy_by_rank.x2 = {'flex', 'flex'};
            
            maxConfig = testCase.DefaultConfig;
            maxConfig.TimeSeries_data.chunking.strategy_by_rank.x2 = {'max', 'max'};
            
            fixedConfig = testCase.DefaultConfig;
            fixedConfig.TimeSeries_data.chunking.strategy_by_rank.x2 = {20, 1000};
            
            % Create test datasets
            flexData = types.core.TimeSeries( ...
                'data', rand(500, 20000), ...
                'data_unit', 'n/a', ...
                'timestamps', 1:20000);
            
            maxData = types.core.TimeSeries( ...
                'data', rand(400, 15000), ...
                'data_unit', 'n/a', ...
                'timestamps', 1:15000);
            
            fixedData = types.core.TimeSeries( ...
                'data', rand(300, 10000), ...
                'data_unit', 'n/a', ...
                'timestamps', 1:10000);
            
            % Add datasets to NWB file
            nwbFile.acquisition.set('flex_chunked_data', flexData);
            nwbFile.acquisition.set('max_chunked_data', maxData);
            nwbFile.acquisition.set('fixed_chunked_data', fixedData);
            
            % Apply configurations
            io.config.applyDatasetConfiguration(nwbFile, nullConfig);
            
            % Verify null chunk dimensions (should use default chunking)
            nullResult = nwbFile.acquisition.get('flex_chunked_data').data;
            testCase.verifyTrue(isa(nullResult, 'types.untyped.DataPipe'), ...
                'Dataset with null chunk dimensions should be converted to DataPipe');
            
            % Apply max configuration
            io.config.applyDatasetConfiguration(nwbFile, maxConfig, 'OverrideExisting', true);
            
            % Verify max chunk dimensions
            maxResult = nwbFile.acquisition.get('max_chunked_data').data;
            testCase.verifyTrue(isa(maxResult, 'types.untyped.DataPipe'), ...
                'Dataset with max chunk dimensions should be converted to DataPipe');
            % % testCase.verifyEqual(maxResult.chunkSize, [40, 15000], ...
            % %     'Chunk size should match dataset dimensions with max specification');
            
            % Apply fixed configuration
            io.config.applyDatasetConfiguration(nwbFile, fixedConfig, 'OverrideExisting', true);
            
            % Verify fixed chunk dimensions
            fixedResult = nwbFile.acquisition.get('fixed_chunked_data').data;
            testCase.verifyTrue(isa(fixedResult, 'types.untyped.DataPipe'), ...
                'Dataset with fixed chunk dimensions should be converted to DataPipe');
            % % testCase.verifyEqual(fixedResult.chunkSize, [20, 1000], ...
            % %     'Chunk size should match fixed specification');
        end
        
        function testClassHierarchyResolution(testCase)
            % Test that configuration is properly resolved through class hierarchy
            nwbFile = tests.factory.NWBFile();
            
            % Create a custom configuration with settings for base and derived types
            hierarchyConfig = testCase.DefaultConfig;
            
            % Set configuration for base type (TimeSeries)
            hierarchyConfig.TimeSeries_data.chunking.strategy_by_rank.x2 = {5, 'flex'};
            
            % Set configuration for derived type (ElectricalSeries)
            hierarchyConfig.ElectricalSeries_data.chunking.strategy_by_rank.x2  = {10, 'flex'};
            
            % Create instances of base and derived types
            baseData = types.core.TimeSeries( ...
                'data', rand(100, 50000), ...
                'data_unit', 'n/a', ...
                'timestamps', 1:50000);
            
            derivedData = types.core.ElectricalSeries( ...
                'data', rand(100, 50000), ...
                'timestamps', 1:50000);
            
            % Add to NWB file
            nwbFile.acquisition.set('base_type_data', baseData);
            nwbFile.acquisition.set('derived_type_data', derivedData);
            
            % Apply configuration
            io.config.applyDatasetConfiguration(nwbFile, hierarchyConfig);
            
            % Verify base type uses its configuration
            baseResult = nwbFile.acquisition.get('base_type_data').data;
            testCase.verifyTrue(isa(baseResult, 'types.untyped.DataPipe'), ...
                'Base type dataset should be converted to DataPipe');
            testCase.verifyEqual(baseResult.chunkSize(1), 5, ...
                'Base type should use its specific configuration');
            
            % Verify derived type uses its configuration
            derivedResult = nwbFile.acquisition.get('derived_type_data').data;
            testCase.verifyTrue(isa(derivedResult, 'types.untyped.DataPipe'), ...
                'Derived type dataset should be converted to DataPipe');
            testCase.verifyEqual(derivedResult.chunkSize(1), 10, ...
                'Derived type should use its specific configuration');
        end
        
        function testMultipleDatasets(testCase)
            % Test handling of multiple datasets in a single neurodata object
            nwbFile = tests.factory.NWBFile();
            
            % Create a neurodata object with multiple datasets
            data = types.core.TimeSeries( ...
                'data', rand(20, 5000000), ...
                'data_unit', 'n/a', ...
                'timestamps', rand(1, 5000000), ... % Also a large dataset
                'starting_time', 0, ...
                'starting_time_rate', 1000);
            
            nwbFile.acquisition.set('multi_dataset_object', data);
            
            % Apply configuration
            io.config.applyDatasetConfiguration(nwbFile, testCase.DefaultConfig);
            
            % Verify both large datasets were converted to DataPipe
            resultObj = nwbFile.acquisition.get('multi_dataset_object');
            testCase.verifyTrue(isa(resultObj.data, 'types.untyped.DataPipe'), ...
                'Data dataset should be converted to DataPipe');
            testCase.verifyTrue(isa(resultObj.timestamps, 'types.untyped.DataPipe'), ...
                'Timestamps dataset should be converted to DataPipe');
            
            % Verify small datasets remain unchanged
            testCase.verifyTrue(isnumeric(resultObj.starting_time), ...
                'Small dataset should remain numeric');
            testCase.verifyTrue(isnumeric(resultObj.starting_time_rate), ...
                'Small dataset should remain numeric');
        end

        function testBasicFunctionality(testCase)
            % Test basic functionality with default configuration
            nwbFile = tests.factory.NWBFile();

            % Should not throw any errors
            io.config.applyDatasetConfiguration(nwbFile, testCase.DefaultConfig);
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
            % Test override behavior for existing DataPipe object

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
            testCase.verifyNotEqual(dataPipe.chunkSize, resultPipe.chunkSize)
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
