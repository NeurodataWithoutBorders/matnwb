classdef nwbExportTest < matlab.unittest.TestCase

    properties
        NwbObject
    end

    methods (TestClassSetup)
        function setupClass(testCase)
            % Get the root path of the matnwb repository
            rootPath = misc.getMatnwbDir();

            % Use a fixture to add the folder to the search path
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
        end
    end

    methods (TestMethodSetup)
        function setupMethod(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            testCase.NwbObject = testCase.initNwbFile();
        end
    end

    methods (Test)
        function testExportDependentAttributeWithMissingParentA(testCase)
            testCase.NwbObject.general_source_script_file_name = 'my_test_script.m';
            testCase.verifyWarning(@(f, fn) nwbExport(testCase.NwbObject, 'test_part1.nwb'), 'NWB:DependentAttributeNotExported')
            
            % Add value for dataset which attribute depends on and export again
            testCase.NwbObject.general_source_script = 'my test';
            testCase.verifyWarningFree(@(f, fn) nwbExport(testCase.NwbObject, 'test_part2.nwb'))
        end

        function testExportDependentAttributeWithMissingParentB(testCase)
            time_series = types.core.TimeSeries( ...
                'data', linspace(0, 0.4, 50), ...
                'starting_time_rate', 10.0, ...
                'description', 'a test series', ...
                'data_unit', 'n/a' ...
            );

            testCase.NwbObject.acquisition.set('time_series', time_series);
            testCase.verifyWarning(@(f, fn) nwbExport(testCase.NwbObject, 'test_part1.nwb'), 'NWB:DependentAttributeNotExported')

            % Add value for dataset which attribute depends on and export again
            time_series.starting_time = 1;
            testCase.verifyWarningFree(@(f, fn) nwbExport(testCase.NwbObject, 'test_part2.nwb'))
        end
    end

    methods (Static)
        function nwb = initNwbFile()
            nwb = NwbFile( ...
                'session_description', 'test file for nwb export', ...
                'identifier', 'export_test', ...
                'session_start_time', datetime("now", 'TimeZone', 'local') );
        end
    end
end
