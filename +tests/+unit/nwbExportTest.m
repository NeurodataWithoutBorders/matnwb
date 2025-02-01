classdef nwbExportTest < matlab.unittest.TestCase

    properties
        NwbObject
        OutputFolder = "out"
    end

    methods (TestClassSetup)
        function setupClass(testCase)
            % Get the root path of the matnwb repository
            rootPath = misc.getMatnwbDir();

            % Use a fixture to add the folder to the search path
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));

            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            generateCore('savedir', '.');
        end
    end

    methods (TestMethodSetup)
        function setupMethod(testCase)
            testCase.NwbObject = testCase.initNwbFile();

            if isfolder( testCase.OutputFolder )
                rmdir(testCase.OutputFolder, "s")
            end
            mkdir(testCase.OutputFolder)
        end
    end

    methods (Test)
        function testExportNwbFileWithMissingRequiredProperties(testCase)
            nwb = NwbFile();
            nwbFilePath = fullfile(testCase.OutputFolder, 'testfile.nwb');
            testCase.verifyError(@(file, path) nwbExport(nwb, nwbFilePath), ...
                'NWB:RequiredPropertyMissing')
        end

        function testExportNwbFileWithMissingRequiredAttribute(testCase)
            processingModule = types.core.ProcessingModule();
            testCase.NwbObject.processing.set('TestModule', processingModule);
            
            nwbFilePath = 'testExportNwbFileWithMissingRequiredAttribute.nwb';
            testCase.verifyError(@(f, fn) nwbExport(testCase.NwbObject, nwbFilePath), ...
                'NWB:RequiredPropertyMissing')

            testCase.NwbObject.processing.remove('TestModule');
        end
              
        function testExportNwbFileWithMissingRequiredLink(testCase)
            electrode = types.core.IntracellularElectrode('description', 'test');
            testCase.NwbObject.general_intracellular_ephys.set('Electrode', electrode)

            nwbFilePath = 'testExportNwbFileWithMissingRequiredLink.nwb';
            testCase.verifyError(@(f, fn) nwbExport(testCase.NwbObject, nwbFilePath), ...
                'NWB:RequiredPropertyMissing')

            testCase.NwbObject.general_intracellular_ephys.remove('Electrode');
        end

        function testExportWithMissingRequiredDependentProperty(testCase)
            nwbFile = testCase.initNwbFile();
            fileName = "testExportWithMissingRequiredDependentProperty";

            % Should work without warning
            testCase.verifyWarningFree( ...
                @(nwbObj, filePath) nwbExport(nwbFile, fileName + "_1.nwb") )

            nwbFile.general_source_script = '.../nwbExportTest.m';

            % Should issue warning work
            testCase.verifyWarning( ...
                @(nwbObj, filePath) nwbExport(nwbFile, fileName + "_2.nwb"), ...
                'NWB:DependentRequiredPropertyMissing')
        end

        function testExportTimeseriesWithMissingTimestampsAndStartingTime(testCase)
            time_series = types.core.TimeSeries( ...
                 'data', linspace(0, 0.4, 50), ...
                 'description', 'a test series', ...
                 'data_unit', 'n/a' ...
             );

             testCase.NwbObject.acquisition.set('time_series', time_series);
             nwbFilePath = fullfile(testCase.OutputFolder, 'testfile.nwb');
             testCase.verifyError(@(f, fn) nwbExport(testCase.NwbObject, nwbFilePath), ...
                 'NWB:CustomConstraintUnfulfilled')
        end

        function testExportDependentAttributeWithMissingParentA(testCase)
            testCase.NwbObject.general_source_script_file_name = 'my_test_script.m';
            nwbFilePath = fullfile(testCase.OutputFolder, 'test_part1.nwb');
            testCase.verifyWarning(@(f, fn) nwbExport(testCase.NwbObject, nwbFilePath), 'NWB:DependentAttributeNotExported')
            
            % Add value for dataset which attribute depends on and export again
            testCase.NwbObject.general_source_script = 'my test';
            nwbFilePath = fullfile(testCase.OutputFolder, 'test_part2.nwb');
            testCase.verifyWarningFree(@(f, fn) nwbExport(testCase.NwbObject, nwbFilePath))
        end

        function testExportTimeseriesWithoutStartingTimeRate(testCase)
            time_series = types.core.TimeSeries( ...
                'data', linspace(0, 0.4, 50), ...
                'starting_time', 1, ...
                'description', 'a test series', ...
                'data_unit', 'n/a' ...
            );
            testCase.NwbObject.acquisition.set('time_series', time_series);
            nwbFilePath = fullfile(testCase.OutputFolder, 'test_part1.nwb');
            testCase.verifyError(@(f, fn) nwbExport(testCase.NwbObject, nwbFilePath), 'NWB:CustomConstraintUnfulfilled')
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
