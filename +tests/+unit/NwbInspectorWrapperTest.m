classdef (SharedTestFixtures = {tests.fixtures.SetEnvironmentVariableFixture}) ...
        NwbInspectorWrapperTest < tests.abstract.NwbTestCase
% nwbExportTest - Unit tests for testing various aspects of exporting to an NWB file.

    methods (TestClassSetup)
        function setupTemporaryWorkingFolder(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test, TestTags={'UsesPython'})
        function testNwbInspector(testCase)
            nwbFile = tests.factory.NWBFile();
            nwbExport(nwbFile, 'temp.nwb');
                
            report = inspectNwbFile('temp.nwb');

            testCase.verifyClass(report, 'table')
            testCase.verifyNotEmpty(report) % Exporting a minimal NWB file should raise some BEST_PRACTICE_SUGGESTIONS;

            % Test using option:
            variableOrder = ["importance", "message", "check_function_name", "object_name"];
            customReport = inspectNwbFile('temp.nwb', 'VariableOrder', variableOrder);
            testCase.verifyEqual(string(customReport.Properties.VariableNames), variableOrder)

            cliReport = inspectNwbFile('temp.nwb', 'UseCLI', true);
            testCase.verifyClass(cliReport, 'table')
            testCase.verifyEqual(size(cliReport), size(report))
            testCase.verifyEqual(report, cliReport) % Note: this might be to strict.
        end

        function testRareExceptionWithMissingLocation(testCase)
            % Test special case where location is a NoneType (for bands table of ecephys tutorial)
            tutorialFolder = fullfile(misc.getMatnwbDir, 'tutorials');            
            % Use a fixture to add the folder to the search path
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(tutorialFolder));
            
            C = evalc( 'run(''ecephys.mlx'')' ); %#ok<NASGU>
            report = inspectNwbFile('ecephys_tutorial.nwb');
            testCase.verifyClass(report, 'table')

            report = inspectNwbFile('ecephys_tutorial.nwb', 'UseCLI', true);
            testCase.verifyClass(report, 'table')
        end
    end
end
