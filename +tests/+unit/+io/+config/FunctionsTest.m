classdef FunctionsTest < matlab.unittest.TestCase
% FunctionsTest - Test inputs and outputs of functions in io.config namespace

    methods (Test)
        function testReadDatasetConfiguration(testCase)
            % Test with no inputs:
            defaultDatasetConfig = io.config.readDatasetConfiguration();
            testCase.verifyClass(defaultDatasetConfig, 'struct')

            % Test with configuration profile name
            cloudDatasetConfig = io.config.readDatasetConfiguration('cloud');
            testCase.verifyClass(cloudDatasetConfig, 'struct')
            testCase.verifyNotEqual(cloudDatasetConfig, defaultDatasetConfig)

            % Test with configuration profile name "none"
            noConfig = io.config.readDatasetConfiguration('none');
            testCase.verifyEmpty(noConfig')
            
            % Test with filepath input
            filename = 'default_dataset_configuration.json';
            configFilePath = fullfile(misc.getMatnwbDir, 'configuration', filename);
            defaultDatasetConfigFromFile = io.config.readDatasetConfiguration('FilePath', configFilePath);
            testCase.verifyEqual(defaultDatasetConfigFromFile, defaultDatasetConfig)
        end

        function testResolveDatasetConfiguration(testCase)
            % Test with no inputs (capture command window output):
            C = evalc("defaultDatasetConfigA = io.config.resolveDatasetConfiguration()"); %#ok<NASGU>
            testCase.verifyClass(defaultDatasetConfigA, 'struct')

            % Test with structure input, i.e already loaded configuration
            defaultDatasetConfigB = io.config.resolveDatasetConfiguration(defaultDatasetConfigA);
            testCase.verifyEqual(defaultDatasetConfigB, defaultDatasetConfigA)

            % Test with profile name
            defaultDatasetConfigC = io.config.resolveDatasetConfiguration("default");
            testCase.verifyEqual(defaultDatasetConfigC, defaultDatasetConfigA)
            
            % Test with filepath input
            filename = 'default_dataset_configuration.json';
            configFilePath = fullfile(misc.getMatnwbDir, 'configuration', filename);
            defaultDatasetConfigD = io.config.resolveDatasetConfiguration(configFilePath);
            testCase.verifyEqual(defaultDatasetConfigD, defaultDatasetConfigA)
        end
    end
end
