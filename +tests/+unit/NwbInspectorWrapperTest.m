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
            if testCase.skipIfNwbInspectorTest()
                return
            end

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
            if testCase.skipIfNwbInspectorTest()
                return
            end
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

        function testErrorWhenPyNwbCannotReadFile(testCase)
            if testCase.skipIfNwbInspectorTest()
                return
            end
            % nwbinspector reports a PyNWB read failure as an ERROR-level
            % message instead of raising. Because no checks run on such a
            % file, inspectNwbFile must raise rather than return a report.
            nwbFile = tests.factory.NWBFile();
            nwbExport(nwbFile, 'unreadable.nwb');
            % Removing a required dataset makes PyNWB fail on read
            deleteLink('unreadable.nwb', '/session_description');

            testCase.verifyError(...
                @() inspectNwbFile('unreadable.nwb'), ...
                'NWB:InspectNwbFile:FileReadError')
            testCase.verifyError(...
                @() inspectNwbFile('unreadable.nwb', 'UseCLI', true), ...
                'NWB:InspectNwbFile:FileReadError')
        end
    end

    methods (Static, Access = private)
        function tf = skipIfNwbInspectorTest()
        % Skip test if SKIP_NWBINSPECTOR_TEST environment variable is set
        % This is used in CI for MATLAB releases that don't support Python 3.10+
        % (nwbinspector requires Python 3.10+)
            skipNwbInspector = getenv("SKIP_NWBINSPECTOR_TEST");
            if ~isempty(skipNwbInspector) && logical(str2double(skipNwbInspector))
                tf = true;
            else
                tf = false;
            end
        end
    end
end

function deleteLink(filename, linkPath)
    fileId = H5F.open(filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
    fileCleanup = onCleanup(@() H5F.close(fileId)); %#ok<NASGU>
    H5L.delete(fileId, linkPath, 'H5P_DEFAULT');
end
