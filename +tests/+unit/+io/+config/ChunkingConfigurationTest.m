classdef ChunkingConfigurationTest < matlab.unittest.TestCase
% Unit tests for chunking settings of the dataset configuration specification

    properties (Constant)
        BytesPerElement = 8 % test data is double
        DataLength = 100 % test data is matrix where each dim is this length
    end

    properties (SetAccess = private)
        DefaultConfig
        TestData
    end

    methods (TestClassSetup)
        function setup(testCase)
            % Setup default and custom configurations before each test
            testCase.DefaultConfig = io.config.readDatasetConfiguration("default");
            testCase.TestData = rand(testCase.DataLength); % double = 8 bytes per data element
        end
    end

    methods (Test)
        function testTargetChunkSize(testCase)
            testConfiguration = testCase.DefaultConfig.Default;
            testConfiguration.chunking.target_chunk_size = 800;

            dataPipe = testCase.getConfiguredDataPipe(testConfiguration);
            testCase.verifyEqual(dataPipe.chunkSize, [100, 1]);

            testConfiguration.chunking.target_chunk_size = 1600;

            dataPipe = testCase.getConfiguredDataPipe(testConfiguration);
            testCase.verifyEqual(dataPipe.chunkSize, [100, 2]);

            testConfiguration.chunking.target_chunk_size = 800*100;
            dataPipe = testCase.getConfiguredDataPipe(testConfiguration);
            testCase.verifyEqual(dataPipe.chunkSize, [100, 100]);
        end

        function testTargetChunkSizeUnit(testCase)
            testConfiguration = testCase.DefaultConfig.Default;
            testConfiguration.chunking.target_chunk_size = 0.8;
            testConfiguration.chunking.target_chunk_size_unit = 'kiB';

            dataPipe = testCase.getConfiguredDataPipe(testConfiguration);
            testCase.verifyEqual(dataPipe.chunkSize, [100, 1]);

            testConfiguration.chunking.target_chunk_size = 1.6;
            
            dataPipe = testCase.getConfiguredDataPipe(testConfiguration);
            testCase.verifyEqual(dataPipe.chunkSize, [100, 2]);

            testConfiguration.chunking.target_chunk_size = 80;
            dataPipe = testCase.getConfiguredDataPipe(testConfiguration);
            testCase.verifyEqual(dataPipe.chunkSize, [100, 100]);

            testConfiguration.chunking.target_chunk_size = 0.08;
            testConfiguration.chunking.target_chunk_size_unit = 'MiB';
            dataPipe = testCase.getConfiguredDataPipe(testConfiguration);
            testCase.verifyEqual(dataPipe.chunkSize, [100, 100]);
        end
        
        function testStrategyByRankFlex(testCase)
            testConfiguration = testCase.DefaultConfig.Default;
            testConfiguration.chunking.target_chunk_size = 800;
            testConfiguration.chunking.strategy_by_rank.x2 = {'flex', 'flex'};

            dataPipe = testCase.getConfiguredDataPipe(testConfiguration);
            expectedSize = round(sqrt([100, 100]));
            testCase.verifyEqual(dataPipe.chunkSize, expectedSize);

            testConfiguration.chunking.target_chunk_size = 1600;
            dataPipe = testCase.getConfiguredDataPipe(testConfiguration);
            expectedSize = round(sqrt([200, 200]));
            testCase.verifyEqual(dataPipe.chunkSize, expectedSize);
        end

        function testStrategyByRankFixed(testCase)
            testConfiguration = testCase.DefaultConfig.Default;
            testConfiguration.chunking.target_chunk_size = 800;
            testConfiguration.chunking.strategy_by_rank.x2 = {10, 10};
            
            dataPipe = testCase.getConfiguredDataPipe(testConfiguration);
            expectedSize = [10, 10];
            testCase.verifyEqual(dataPipe.chunkSize, expectedSize);

            testConfiguration.chunking.target_chunk_size = 1600;

            % Should ignore the target_chunk_size
            dataPipe = testCase.getConfiguredDataPipe(testConfiguration);
            expectedSize = [10, 10];
            testCase.verifyEqual(dataPipe.chunkSize, expectedSize);
        end

        function testStrategyByRankMax(testCase)
            testConfiguration = testCase.DefaultConfig.Default;
            testConfiguration.chunking.target_chunk_size = 800;
            testConfiguration.chunking.strategy_by_rank.x2 = {'max', 'max'};
            
            % Should ignore the target_chunk_size
            dataPipe = testCase.verifyWarning( ...
                @() testCase.getConfiguredDataPipe(testConfiguration), ...
                'NWB:ComputeChunkSizeFromConfig:TargetSizeExceeded');
            expectedSize = [100, 100];
            testCase.verifyEqual(dataPipe.chunkSize, expectedSize);
        end
    end

    methods (Access = private)
        function dataPipe = getConfiguredDataPipe(testCase, testConfiguration)
            % getConfiguredDataPipe - Returned a configured datapipe given
            % a test configuration.
            dataPipe = io.config.internal.configureDataPipeFromData(...
                testCase.TestData, testConfiguration);
        end
    end
end
