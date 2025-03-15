classdef NwbInspectorWrapperTest < tests.abstract.NwbTestCase
% nwbExportTest - Unit tests for testing various aspects of exporting to an NWB file.

    methods (TestClassSetup)
        function setupTemporaryWorkingFolder(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
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
    end
end
