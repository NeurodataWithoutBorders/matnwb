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

        function testEmbeddedSpecs(testCase)
            
            nwbFileName = 'testEmbeddedSpecs.nwb';

            % Install extension. 
            nwbInstallExtension(["ndx-miniscope", "ndx-photostim"], 'savedir', '.')
            
            % Export a file not using a type from an extension
            nwb = testCase.initNwbFile();
            
            nwbExport(nwb, nwbFileName);
            embeddedNamespaces = io.spec.listEmbeddedSpecNamespaces(nwbFileName);
            testCase.verifyEmpty(embeddedNamespaces)

            ts = types.core.TimeSeries('data', rand(1,10), 'timestamps', 1:10);
            nwb.acquisition.set('test', ts);

            nwbExport(nwb, nwbFileName);
            embeddedNamespaces = io.spec.listEmbeddedSpecNamespaces(nwbFileName);
            
            % Verify that extension namespace is not part of embedded specs
            testCase.verifyEqual(sort(embeddedNamespaces), {'core', 'hdmf-common'})

            % Add type for extension.
            testDevice = types.ndx_photostim.Laser('model', 'Spectra-Physics');
            nwb.general_devices.set('TestDevice', testDevice);
            
            nwbExport(nwb, nwbFileName);
            embeddedNamespaces = io.spec.listEmbeddedSpecNamespaces(nwbFileName);

            % Verify that extension namespace is part of embedded specs.
            testCase.verifyEqual(sort(embeddedNamespaces), {'core', 'hdmf-common', 'ndx-photostim'})

            % When we remove the TestDevice from the NWB object, and
            % re-export, the ndx-photostim namespace/extension should be 
            % removed from the embedded specifications in the file, because
            % there are not longer any types from the ndx-photostim
            % extension in the file.

            % Please note: The following commands only removes the
            % TestDevice from the nwbFile object, not from the actual file
            % See matnwb issue #649:
            % https://github.com/NeurodataWithoutBorders/matnwb/issues/649
            nwb.general_devices.remove('TestDevice');
            nwbExport(nwb, nwbFileName);
            
            embeddedNamespaces = io.spec.listEmbeddedSpecNamespaces(nwbFileName);
            testCase.verifyEqual(sort(embeddedNamespaces), {'core', 'hdmf-common'})
        end

        function testWarnIfMissingNamespaceSpecification(testCase)
            % Tests the case where a cached namespace specification is
            % deleted from disk before an nwb object containing types from
            % that namespace is exported to file.
            
            nwbFileName = 'testWarnIfMissingNamespaceSpecification.nwb';

            % Install extension. 
            nwbInstallExtension("ndx-photostim", 'savedir', '.')
            
            % Export a file not using a type from an extension
            nwb = testCase.initNwbFile();
            
            % Add a timeseries object
            ts = types.core.TimeSeries('data', rand(1,10), 'timestamps', 1:10);
            nwb.acquisition.set('test', ts);
            
            % Add type from ndx-photostim extension.
            testDevice = types.ndx_photostim.Laser('model', 'Spectra-Physics');
            nwb.general_devices.set('TestDevice', testDevice);

            % Simulate the rare case where a user might delete the cached
            % namespace specification before exporting a file
            cachedNamespaceSpec = fullfile("namespaces/ndx-photostim.mat");
            delete(cachedNamespaceSpec)
            
            % Test that warning for missing namespace works
            testCase.verifyWarning(...
                @() nwbExport(nwb, nwbFileName), ...
                'NWB:validators:MissingEmbeddedNamespace')
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
