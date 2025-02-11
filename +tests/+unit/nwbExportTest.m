classdef nwbExportTest < tests.abstract.NwbTestCase

    properties
        NwbObject
        OutputFolder = "out"
    end

    methods (TestClassSetup)
        function setupClass(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
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
            % This should raise an error because ProcessingModule requires the 
            % 'description' property to be set (description is a required 
            % attribute of ProcessingModule).

            processingModule = types.core.ProcessingModule();
            testCase.NwbObject.processing.set('TestModule', processingModule);
            
            nwbFilePath = 'testExportNwbFileWithMissingRequiredAttribute.nwb';
            testCase.verifyError(@(f, fn) nwbExport(testCase.NwbObject, nwbFilePath), ...
                'NWB:RequiredPropertyMissing')

            testCase.NwbObject.processing.remove('TestModule');
        end
              
        function testExportNwbFileWithMissingRequiredLink(testCase)
            % Here we try to export an IntracellularElectrode with an unset
            % device. The device is a required property (Link-type) of the 
            % IntracellularElectrode and exporting the object should throw
            % an error.

            electrode = types.core.IntracellularElectrode('description', 'test');
            testCase.NwbObject.general_intracellular_ephys.set('Electrode', electrode);

            nwbFilePath = 'testExportNwbFileWithMissingRequiredLink.nwb';
            testCase.verifyError(@(f, fn) nwbExport(testCase.NwbObject, nwbFilePath), ...
                'NWB:RequiredPropertyMissing')

            % Clean up: the NwbObject is reused by other tests.
            testCase.NwbObject.general_intracellular_ephys.remove('Electrode');
        end

        function testExportWithMissingRequiredDependentProperty(testCase)
            nwbFile = testCase.initNwbFile();
            fileName = "testExportWithMissingRequiredDependentProperty";

            % Should work without warning
            testCase.verifyWarningFree( ...
                @(nwbObj, filePath) nwbExport(nwbFile, fileName + "_1.nwb") )

            % Now we add a value to the "general_source_script" property. This
            % is a dataset with a required attribute called "file_name".
            % Hence, the property "general_source_script_file_name" becomes
            % required when we add a value to the "general_source_script"
            % property.
            nwbFile.general_source_script = '.../nwbExportTest.m';

            % Verify that exporting the file issues warning that a required
            % property (i.e general_source_script_file_name) is missing

            testCase.verifyWarning( ...
                @(nwbObj, filePath) nwbExport(nwbFile, fileName + "_2.nwb"), ...
                'NWB:DependentRequiredPropertyMissing')
        end

        function testExportFileWithAttributeOfEmptyDataset(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            
            nwbFile = testCase.initNwbFile();

            % Add device to nwb object
            device = types.core.Device();
            nwbFile.general_devices.set('Device', device);
            
            imaging_plane = types.core.ImagingPlane( ...
                'device', types.untyped.SoftLink(device), ...
                'excitation_lambda', 600., ...
                'indicator', 'GFP', ...
                'location', 'my favorite brain location');
            nwbFile.general_optophysiology.set('ImagingPlane', imaging_plane);

            testCase.verifyWarningFree(...
                @() nwbExport(nwbFile, 'test_1.nwb'))

            % Change value for attribute of the grid_spacing dataset.
            testCase.applyFixture(...
                SuppressedWarningsFixture('NWB:AttributeDependencyNotSet'))
            imaging_plane.grid_spacing_unit = "microns";

            % Because grid_spacing is not set, this attribute value is not
            % exported to the file. Verify that warning is issued on export.
            testCase.verifyWarning(...
                @() nwbExport(nwbFile, 'test_2.nwb'), ...
                'NWB:DependentAttributeNotExported')
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
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            testCase.applyFixture(...
                SuppressedWarningsFixture('NWB:AttributeDependencyNotSet'))

            testCase.NwbObject.general_source_script_file_name = 'my_test_script.m';
            nwbFilePath = fullfile(testCase.OutputFolder, 'test_part1.nwb');
            testCase.verifyWarning(...
                @(f, fn) nwbExport(testCase.NwbObject, nwbFilePath), ...
                'NWB:DependentAttributeNotExported')
            
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
            generatedTypesOutputFolder = testCase.getTypesOutputFolder();
            nwbInstallExtension(["ndx-miniscope", "ndx-photostim"], 'savedir', generatedTypesOutputFolder)
            testCase.addTeardown(@() testCase.clearExtension("ndx-miniscope"))
            testCase.addTeardown(@() testCase.clearExtension("ndx-photostim"))
            
            % Export a file not using a type from an extension
            nwb = testCase.initNwbFile();
            
            nwbExport(nwb, nwbFileName);
            embeddedNamespaces = io.spec.listEmbeddedSpecNamespaces(nwbFileName);
            testCase.verifyEmpty(embeddedNamespaces)

            ts = types.core.TimeSeries(...
                'data', rand(1,10), 'timestamps', 1:10, 'data_unit', 'test');
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
            
            % A cached namespace is manually deleted in this test, so will
            % use a fixture to ignore the warning for a missing file when
            % the installed extension is cleared.
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            testCase.applyFixture(SuppressedWarningsFixture('MATLAB:DELETE:FileNotFound'))
            
            nwbFileName = 'testWarnIfMissingNamespaceSpecification.nwb';

            % Install extension.
            generatedTypesOutputFolder = testCase.getTypesOutputFolder();
            nwbInstallExtension("ndx-photostim", 'savedir', generatedTypesOutputFolder)
            testCase.addTeardown(@() testCase.clearExtension("ndx-photostim"))
            
            % Export a file not using a type from an extension
            nwb = testCase.initNwbFile();
            
            % Add a timeseries object
            ts = types.core.TimeSeries(...
                'data', rand(1,10), 'timestamps', 1:10, 'data_unit', 'test');
            nwb.acquisition.set('test', ts);
            
            % Add type from ndx-photostim extension.
            testDevice = types.ndx_photostim.Laser('model', 'Spectra-Physics');
            nwb.general_devices.set('TestDevice', testDevice);

            % Simulate the rare case where a user might delete the cached
            % namespace specification before exporting a file
            cachedNamespaceSpec = fullfile(generatedTypesOutputFolder, "namespaces", "ndx-photostim.mat");
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
