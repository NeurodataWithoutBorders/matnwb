classdef (Abstract, SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
        NwbTestCase < matlab.unittest.TestCase
% NwbTestCase - Abstract class providing a shared fixture, and utility
% methods for running tests dependent on generating neurodata type classes

    methods (Access = protected)
        function typesOutputFolder = getTypesOutputFolder(testCase)
            F = testCase.getSharedTestFixtures();
            isMatch = arrayfun(@(x) isa(x, 'tests.fixtures.GenerateCoreFixture'), F);
            F = F(isMatch);
            
            typesOutputFolder = F.TypesOutputFolder;
        end

        function applyTestSchemaFixture(testCase, schemaName)
        % Generate a test schema extension using fixture for cleanup
            import tests.fixtures.ExtensionGenerationFixture
            
            typesOutputFolder = testCase.getTypesOutputFolder();
            namespaceFilePath = tests.util.getTestSchemaFilepath(schemaName);
            
            testCase.applyFixture( ...
                ExtensionGenerationFixture(namespaceFilePath, typesOutputFolder) )
        end

        function installExtension(testCase, extensionName)
            typesOutputFolder = testCase.getTypesOutputFolder();
            
            % Use evalc to suppress output while running tests.
            matlabExpression = sprintf(...
                'nwbInstallExtension("%s", "savedir", "%s")', ...
                extensionName, typesOutputFolder);
            evalc(matlabExpression);
        end

        function clearExtension(testCase, extensionName)
            extensionName = char(extensionName);
            namespaceFolderName = strrep(extensionName, '-', '_');
            typesOutputFolder = testCase.getTypesOutputFolder();
            rmdir(fullfile(typesOutputFolder, '+types', ['+', namespaceFolderName]), 's')
            delete(fullfile(typesOutputFolder, 'namespaces', [extensionName '.mat']))
        end
    end

    methods (Static, Access = protected)
        function [nwbFile, nwbFileCleanup] = readNwbFileWithPynwb(nwbFilename)
            [nwbFile, nwbFileCleanup] = tests.util.readWithPynwb(nwbFilename);
        end
    
        function nwbFilename = getRandomFilename()
            % Assumes that this method is called from a test method
            functionCallStackTrace = dbstack();
            testName = regexp(functionCallStackTrace(2).name, '\w*$', 'match', 'once');
            nwbFilename = sprintf('%s_%05d.nwb', testName, randi(9999));
        end
    end

    methods (Access = protected)
        function skipIfNwbInspectorTestSkipped(testCase)
        % Skip test if SKIP_NWBINSPECTOR_TEST environment variable is set
        % This is used in CI for MATLAB releases that don't support Python 3.10+
        % (nwbinspector requires Python 3.10+)
            skipNwbInspector = getenv("SKIP_NWBINSPECTOR_TEST");
            if ~isempty(skipNwbInspector) && logical(str2double(skipNwbInspector))
                testCase.assumeFail(...
                    'Skipping nwbinspector test (Python version does not support nwbinspector)');
            end
        end
    end
end