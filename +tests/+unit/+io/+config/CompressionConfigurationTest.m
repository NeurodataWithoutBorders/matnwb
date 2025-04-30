classdef CompressionConfigurationTest < matlab.unittest.TestCase
% Unit tests for compression settings of the dataset configuration specification

    properties
        DefaultConfig
        TestData
    end

    methods (TestClassSetup)
        function setup(testCase)
            % Setup default and custom configurations before each test
            testCase.DefaultConfig = io.config.readDatasetConfiguration("default");
            testCase.TestData = rand(100,100);
        end
    end

    methods (Test)
        function testMissingCompressionLevelForDefaultMethod(testCase)
            testConfiguration = testCase.DefaultConfig.Default;
            testConfiguration.compression.parameters = ...
                rmfield(testConfiguration.compression.parameters, "level");

            dataPipe = testCase.verifyWarning(...
                @() testCase.getConfiguredDataPipe(testConfiguration), ...
                'NWB:DataPipeConfiguration:LevelParameterNotSet');

            testCase.verifyEqual(dataPipe.compressionLevel, 3);
        end

        function testCustomCompressionLevelForDefaultMethod(testCase)
            CUSTOM_COMPRESSION_LEVEL = 9;
            
            testConfiguration = testCase.DefaultConfig.Default;
            testConfiguration.compression.parameters.level = CUSTOM_COMPRESSION_LEVEL;

            dataPipe = testCase.getConfiguredDataPipe(testConfiguration);

            testCase.verifyEqual(dataPipe.compressionLevel, CUSTOM_COMPRESSION_LEVEL);
        end

        function testCompressionWithShufflePrefilter(testCase)
            testConfiguration = testCase.DefaultConfig.Default;
            testConfiguration.compression.prefilters = "shuffle";

            dataPipe = testCase.getConfiguredDataPipe(testConfiguration);
            testCase.verifyTrue(dataPipe.hasShuffle)

            dataPipeProperties = dataPipe.internal.pipeProperties;

            testCase.verifySize(dataPipeProperties, [1,3]);

            propertyTypes = cellfun(@(c) class(c), dataPipeProperties, 'uni', false);
            testCase.verifyTrue(contains('types.untyped.datapipe.properties.Shuffle', propertyTypes))
        end

        function testCompressionWithInvalidPrefilter(testCase)
            testConfiguration = testCase.DefaultConfig.Default;
            testConfiguration.compression.prefilters = "invalid";
                      
            dataPipe = testCase.getConfiguredDataPipe(testConfiguration);
            dataPipeProperties = dataPipe.internal.pipeProperties;

            % No extra property filter should be set in addition to
            % chunking + compression
            testCase.verifySize(dataPipeProperties, [1,2]);
        end
    end

    methods (Test, TestTags={'UsesDynamicallyLoadedFilters'})
        
        function testCustomCompressionMethod(testCase)
            CUSTOM_COMPRESSION_METHOD = "ZStandard";
            
            testConfiguration = testCase.DefaultConfig.Default;
            testConfiguration.compression.method = CUSTOM_COMPRESSION_METHOD;

            dataPipe = testCase.getConfiguredDataPipe(testConfiguration);
            dynamicFilterObject = testCase.getDynamicFilterFromDataPipe(dataPipe);
            
            actualFilterName = string(dynamicFilterObject.dynamicFilter);
            expectedFiltername = CUSTOM_COMPRESSION_METHOD;

            testCase.verifyEqual(actualFilterName, expectedFiltername);
        end
        
        function testCustomCompressionLevelForCustomCompressionMethod(testCase)
            CUSTOM_COMPRESSION_METHOD = "ZStandard";
            CUSTOM_COMPRESSION_LEVEL = 9;

            testConfiguration = testCase.DefaultConfig.Default;
            testConfiguration.compression.method = CUSTOM_COMPRESSION_METHOD;
            testConfiguration.compression.parameters.level = CUSTOM_COMPRESSION_LEVEL;

            dataPipe = testCase.getConfiguredDataPipe(testConfiguration);
            dynamicFilterObject = testCase.getDynamicFilterFromDataPipe(dataPipe);
            
            actualFilterName = string(dynamicFilterObject.dynamicFilter);
            expectedFiltername = CUSTOM_COMPRESSION_METHOD;

            testCase.verifyEqual(actualFilterName, expectedFiltername);
            testCase.verifyEqual(dynamicFilterObject.parameters, CUSTOM_COMPRESSION_LEVEL);
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

    methods (Static, Access=private)
        function dynamicFilter = getDynamicFilterFromDataPipe(dataPipe)
            isDynamicFilter = cellfun(@(c) ...
                isa(c, 'types.untyped.datapipe.properties.DynamicFilter'), ...
                dataPipe.internal.pipeProperties, 'UniformOutput', true);
    
            dynamicFilter = dataPipe.internal.pipeProperties{isDynamicFilter};
        end
    end
end
