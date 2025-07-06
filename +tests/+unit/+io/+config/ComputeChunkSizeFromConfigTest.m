classdef ComputeChunkSizeFromConfigTest < matlab.unittest.TestCase
% Unit tests for computeChunkSizeFromConfig function
% Tests the function that computes chunk sizes based on configuration

    properties (TestParameter)
        ChunkSizeUnit = {'bytes', 'kiB', 'MiB', 'GiB'}
    end

    methods (TestClassSetup)
        function suppressExpectedWarning(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            warningToSuppress = 'NWB:ComputeChunkSizeFromConfig:TargetSizeExceeded';
            testCase.applyFixture(SuppressedWarningsFixture(warningToSuppress))
        end
    end

    methods (Test)
        function testBasicValidInput(testCase)
            % Test with basic valid input - 2D array with mixed constraints
            A = rand(10, 20); % 2D array, 1600 bytes
            configuration.strategy_by_rank.x2 = {5, 'max'};
            configuration.target_chunk_size = 1000; % bytes
            configuration.target_chunk_size_unit = 'bytes';
            
            expectedChunkSize = [5, 20];
            actualChunkSize = io.config.internal.computeChunkSizeFromConfig(A, configuration);
            
            testCase.verifyEqual(actualChunkSize, expectedChunkSize);
        end
           
        function test1DArray(testCase)
            % Test with 1D array (column vector) and flex dimension
            A = rand(100, 1); % Column vector, 800 bytes
            configuration.strategy_by_rank.x1 = {'flex'};
            configuration.target_chunk_size = 500; % bytes
            configuration.target_chunk_size_unit = 'bytes';
            
            expectedChunkSize = [round(100/800*500) 1];
            actualChunkSize = io.config.internal.computeChunkSizeFromConfig(A, configuration);
            
            testCase.verifySize(actualChunkSize, [1, 2]); % Should be [n, 1]
            testCase.verifyEqual(actualChunkSize, expectedChunkSize)
        end
        
        function test1DArrayRow(testCase)
            % Test with 1D array (row vector) and flex dimension
            A = rand(1, 100); % Row vector, 800 bytes
            configuration.strategy_by_rank.x1 = {'flex'};
            configuration.target_chunk_size = 500; % bytes
            configuration.target_chunk_size_unit = 'bytes';
            
            expectedChunkSize = [1, round(100/800*500)];
            actualChunkSize = io.config.internal.computeChunkSizeFromConfig(A, configuration);
            
            testCase.verifySize(actualChunkSize, [1, 2]); % Should be [1, n]
            testCase.verifyEqual(actualChunkSize, expectedChunkSize)
        end

        function test2DArrayMultipleFlex(testCase)
            % Test with 2D array and multiple flex dimensions
            A = rand(50, 50); % 20000 bytes
            configuration.strategy_by_rank.x2 = {'flex', 'flex'};
            configuration.target_chunk_size = 1000; % bytes
            configuration.target_chunk_size_unit = 'bytes';
            
            expectedChunkSize = repmat( round(sqrt(numel(A) / (20000/1000) )), 1, 2);
            actualChunkSize = io.config.internal.computeChunkSizeFromConfig(A, configuration);
            
            testCase.verifySize(actualChunkSize, [1, 2]);
            testCase.verifyEqual(actualChunkSize, expectedChunkSize)
        end

        function testFlexAndFixedDimensions(testCase)
            % Test with a mix of flex and fixed dimensions
            A = rand(30, 40); % 9600 bytes
            configuration.strategy_by_rank.x2 = {'flex', 10};
            configuration.target_chunk_size = 5000; % bytes
            configuration.target_chunk_size_unit = 'bytes';
            
            expectedChunkSize = [30, 10];
            actualChunkSize = io.config.internal.computeChunkSizeFromConfig(A, configuration);
            
            testCase.verifySize(actualChunkSize, [1, 2]);
            testCase.verifyEqual(actualChunkSize, expectedChunkSize)
        end
        
        function test3DArrayMultipleMax(testCase)
            % Test with 3D array and multiple max dimensions
            A = rand(20, 30, 40); % 192000 bytes
            configuration.strategy_by_rank.x3 = {'max', 'max', 'max'};
            configuration.target_chunk_size = 2000; % bytes
            configuration.target_chunk_size_unit = 'bytes';
            
            expectedChunkSize = [20, 30, 40];
            actualChunkSize = io.config.internal.computeChunkSizeFromConfig(A, configuration);
            
            testCase.verifyEqual(actualChunkSize, expectedChunkSize);
        end

        function test4DArrayFixedDimensions(testCase)
            % Test with 4D array and fixed dimensions
            A = rand(10, 10, 10, 10);
            configuration.strategy_by_rank.x4 = {5, 5, 5, 5};
            configuration.target_chunk_size = 100; % bytes
            configuration.target_chunk_size_unit = 'bytes';
            
            expectedChunkSize = [5, 5, 5, 5];
            actualChunkSize = io.config.internal.computeChunkSizeFromConfig(A, configuration);
            
            testCase.verifyEqual(actualChunkSize, expectedChunkSize);
        end

        function testDimensionSmallerThanConstraint(testCase)
            % Test with a mix of flex and fixed dimensions
            A = rand(30, 40); % 9600 bytes
            configuration.strategy_by_rank.x2 = {'flex', 100};
            configuration.target_chunk_size = 5000; % bytes
            configuration.target_chunk_size_unit = 'bytes';
            
            expectedChunkSize = [round(numel(A)/40/9600*5000) 40];
            actualChunkSize = io.config.internal.computeChunkSizeFromConfig(A, configuration);
            
            testCase.verifySize(actualChunkSize, [1, 2]);
            testCase.verifyEqual(actualChunkSize, expectedChunkSize)
        end

        function testMixedConstraints(testCase)
            % Test with mixed constraints (max, flex, fixed)
            A = rand(15, 25, 35); % 105000 bytes
            configuration.strategy_by_rank.x3 = {'max', 'flex', 10};
            configuration.target_chunk_size = 2000; % bytes
            configuration.target_chunk_size_unit = 'bytes';
            
            actualChunkSize = io.config.internal.computeChunkSizeFromConfig(A, configuration);
            
            % Verify the chunk size is reasonable
            testCase.verifySize(actualChunkSize, [1, 3]);
            testCase.verifyEqual(actualChunkSize(1), 15); % max
            testCase.verifyGreaterThanOrEqual(actualChunkSize(2), 1); % flex
            testCase.verifyLessThanOrEqual(actualChunkSize(2), 25); % flex
            testCase.verifyEqual(actualChunkSize(3), 10); % fixed
        end
        
        function testMissingRankConfiguration(testCase)
            % Test error when configuration for the rank is missing
            A = rand(10, 10);
            configuration.strategy_by_rank.x3 = {'max', 'max', 'max'}; % Only has config for rank 3
            configuration.target_chunk_size = 1000;
            configuration.target_chunk_size_unit = 'bytes';
            
            % Verify that an error is thrown
            testCase.verifyError(...
                @() io.config.internal.computeChunkSizeFromConfig(A, configuration), ...
                'NWB:ComputeChunkSizeFromConfig:MatchingRankNotFound');
        end
        
        function testInvalidConstraint(testCase)
            % Test error when an invalid constraint is provided
            A = rand(10, 10);
            configuration.strategy_by_rank.x2 = {'invalid', 5};
            configuration.target_chunk_size = 1000;
            configuration.target_chunk_size_unit = 'bytes';
            
            % Verify that an error is thrown
            testCase.verifyError(...
                @() io.config.internal.computeChunkSizeFromConfig(A, configuration), ...
                'NWB:ComputeChunkSizeFromConfig:InvalidConstraint');
        end
        
        function testTargetChunkSizeUnits(testCase, ChunkSizeUnit)
            % Test different target_chunk_size_unit values
            % This test verifies that the getTargetChunkSizeInBytes function
            % correctly converts from different units to bytes
            
            % Create a configuration with a specific unit
            configuration.strategy_by_rank.x1 = {'flex'};
            configuration.target_chunk_size = 1; % 1 unit of the specified type
            configuration.target_chunk_size_unit = ChunkSizeUnit;
            
            % Expected conversion factors for each unit
            conversionFactors = struct(...
                'bytes', 1, ...
                'kiB', 2^10, ... % 1 kiB = 2^10 bytes
                'MiB', 2^20, ... % 1 MiB = 2^20 bytes
                'GiB', 2^30 ... % 1 GiB = 2^30 bytes
            );
            
            % Calculate expected bytes based on the unit
            expectedBytes = conversionFactors.(ChunkSizeUnit);
            
            % Get the actual bytes using the function
            actualBytes = io.config.internal.getTargetChunkSizeInBytes(configuration);
            
            % Verify the conversion is correct
            testCase.verifyEqual(actualBytes, expectedBytes, ...
                sprintf('Conversion from %s to bytes failed', ChunkSizeUnit));
            
            % Test with a 1D array to ensure the computed chunk size is reasonable
            numElementsFor1GiB = 2^30; % Using uint8 data type, 1 byte per element
            A = zeros(numElementsFor1GiB, 1, 'uint8'); % 1GiB
            actualChunkSize = io.config.internal.computeChunkSizeFromConfig(A, configuration);
            
            testCase.verifySize(actualChunkSize, [1, 2]);
            testCase.verifyEqual(actualChunkSize, [expectedBytes, 1]);
        end
    end
end
