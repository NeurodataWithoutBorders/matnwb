classdef nwbExportTest < tests.abstract.NwbTestCase
% nwbExportTest - Unit tests for testing various aspects of exporting to an NWB file.

    methods (TestClassSetup)
        function setupTemporaryWorkingFolder(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (TestMethodSetup)
        % No method setup
    end

    methods (Test)
        function testExportNwbFileWithMissingRequiredProperties(testCase)
            nwb = NwbFile();
            nwbFilePath = testCase.getRandomFilename();

            testCase.verifyError(...
                @() nwbExport(nwb, nwbFilePath), ...
                'NWB:RequiredPropertyMissing')
        end

        function testExportNwbFileWithMissingRequiredAttribute(testCase)
            % This should raise an error because ProcessingModule requires the 
            % 'description' property to be set (description is a required 
            % attribute of ProcessingModule).

            nwbFile = tests.factory.NWBFile();
            processingModule = types.core.ProcessingModule();
            nwbFile.processing.set('TestModule', processingModule);
            
            nwbFilePath = testCase.getRandomFilename();
            
            testCase.verifyError(...
                @() nwbExport(nwbFile, nwbFilePath), ...
                'NWB:RequiredPropertyMissing')
        end
              
        function testExportNwbFileWithMissingRequiredLink(testCase)
            % Here we try to export an IntracellularElectrode with an unset
            % device. The device is a required property (Link-type) of the 
            % IntracellularElectrode and exporting the object should throw
            % an error.

            nwbFile = tests.factory.NWBFile();
            electrode = types.core.IntracellularElectrode('description', 'test');
            nwbFile.general_intracellular_ephys.set('Electrode', electrode);

            nwbFilePath = testCase.getRandomFilename();
            testCase.verifyError(...
                @() nwbExport(nwbFile, nwbFilePath), ...
                'NWB:RequiredPropertyMissing')
        end

        function testExportWithMissingRequiredDependentProperty(testCase)
            nwbFile = tests.factory.NWBFile();
            
            nwbFilePath = testCase.getRandomFilename();
            nwbExport(nwbFile, nwbFilePath) % Should work without error

            % Now we add a value to the "general_source_script" property. This
            % is a dataset with a required attribute called "file_name".
            % Hence, the property "general_source_script_file_name" becomes
            % required when we add a value to the "general_source_script"
            % property.
            nwbFile.general_source_script = '.../nwbExportTest.m';

            % Verify that exporting the file throws an error, stating that a 
            % required property (i.e general_source_script_file_name) is missing
            nwbFilePath = testCase.getRandomFilename();
            testCase.verifyError( ...
                @() nwbExport(nwbFile, nwbFilePath), ...
                'NWB:DependentRequiredPropertyMissing')
        end

        function testExportDependentAttributeWithMissingParent(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            testCase.applyFixture(...
                SuppressedWarningsFixture('NWB:AttributeDependencyNotSet'))

            nwbFile = tests.factory.NWBFile();
            nwbFile.general_source_script_file_name = 'my_test_script.m';
            nwbFilePath = testCase.getRandomFilename();
            
            testCase.verifyWarning(...
                @() nwbExport(nwbFile, nwbFilePath), ...
                'NWB:DependentAttributeNotExported')
            
            % Add value for dataset which attribute depends on and export again
            nwbFile.general_source_script = 'my test';
            nwbFilePath = testCase.getRandomFilename();
            
            testCase.verifyWarningFree(@() nwbExport(nwbFile, nwbFilePath))
        end

        function testExportFileWithAttributeOfEmptyDataset(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            
            nwbFile = tests.factory.NWBFile();
            
            device = types.core.Device();
            nwbFile.general_devices.set('Device', device);
            
            imagingPlane = tests.factory.ImagingPlane(device);
            nwbFile.general_optophysiology.set('ImagingPlane', imagingPlane);
   
            nwbFilePath = testCase.getRandomFilename();
            testCase.verifyWarningFree(...
                @() nwbExport(nwbFile, nwbFilePath))

            % Change value for attribute of the grid_spacing dataset.
            testCase.applyFixture(...
                SuppressedWarningsFixture('NWB:AttributeDependencyNotSet'))
            imagingPlane.grid_spacing_unit = "microns";

            % Because grid_spacing is not set, this attribute value is not
            % exported to the file. Verify that warning is issued on export.
            nwbFilePath = testCase.getRandomFilename();
            testCase.verifyWarning(...
                @() nwbExport(nwbFile, nwbFilePath), ...
                'NWB:DependentAttributeNotExported')
        end

        function testExportTimeseriesWithMissingTimestampsAndStartingTime(testCase)
            nwbFile = tests.factory.NWBFile();
            
            time_series = types.core.TimeSeries( ...
                 'data', linspace(0, 0.4, 50), ...
                 'description', 'a test series', ...
                 'data_unit', 'n/a' ...
            );
            nwbFile.acquisition.set('time_series', time_series);
            
            nwbFilePath = testCase.getRandomFilename();
            testCase.verifyError(...
                @() nwbExport(nwbFile, nwbFilePath), ...
                'NWB:CustomConstraintUnfulfilled')
        end
        
        function testExportTimeseriesWithoutStartingTimeRate(testCase)
            nwbFile = tests.factory.NWBFile();
            
            time_series = types.core.TimeSeries( ...
                'data', linspace(0, 0.4, 50), ...
                'starting_time', 1, ...
                'description', 'a test series', ...
                'data_unit', 'n/a' ...
            );
            nwbFile.acquisition.set('time_series', time_series);
            
            nwbFilePath = testCase.getRandomFilename();
            testCase.verifyError(...
                @() nwbExport(nwbFile, nwbFilePath), ...
                'NWB:CustomConstraintUnfulfilled')
        end

        function testEmbeddedSpecs(testCase)
            
            % Install extensions, one will be used, the other will not. 
            testCase.installExtension("ndx-miniscope")
            testCase.addTeardown(@() testCase.clearExtension("ndx-miniscope"))
            testCase.installExtension("ndx-photostim")
            testCase.addTeardown(@() testCase.clearExtension("ndx-photostim"))
            
            % Export a file not using a type from an extension
            nwb = tests.factory.NWBFile();
            nwbFilePath = testCase.getRandomFilename();
            nwbExport(nwb, nwbFilePath);

            % Verify that core and hdmf-common were embedded in "empty" file
            embeddedNamespaces = io.spec.listEmbeddedSpecNamespaces(nwbFilePath);
            testCase.verifyEqual(sort(embeddedNamespaces), {'core', 'hdmf-common'})

            ts = tests.factory.TimeSeriesWithTimestamps();
            nwb.acquisition.set('test', ts);

            nwbExport(nwb, nwbFilePath);
            embeddedNamespaces = io.spec.listEmbeddedSpecNamespaces(nwbFilePath);
            
            % Verify that extension namespace is not part of embedded specs
            testCase.verifyEqual(sort(embeddedNamespaces), {'core', 'hdmf-common'})

            % Add type for extension.
            testDevice = types.ndx_photostim.Laser('model', 'Spectra-Physics');
            nwb.general_devices.set('TestDevice', testDevice);
            
            nwbExport(nwb, nwbFilePath);
            embeddedNamespaces = io.spec.listEmbeddedSpecNamespaces(nwbFilePath);

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
            nwbExport(nwb, nwbFilePath);
            
            embeddedNamespaces = io.spec.listEmbeddedSpecNamespaces(nwbFilePath);
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
            
            nwbFilePath = testCase.getRandomFilename();

            % Install extension.
            testCase.installExtension("ndx-photostim");
            testCase.addTeardown(@() testCase.clearExtension("ndx-photostim"))
            
            % Export a file not using a type from an extension
            nwb = tests.factory.NWBFile();
            
            % Add a timeseries object
            ts = tests.factory.TimeSeriesWithTimestamps();
            nwb.acquisition.set('test', ts);
            
            % Add type from ndx-photostim extension.
            testDevice = types.ndx_photostim.Laser('model', 'Spectra-Physics');
            nwb.general_devices.set('TestDevice', testDevice);

            % Simulate the rare case where a user might delete the cached
            % namespace specification before exporting a file
            generatedTypesOutputFolder = testCase.getTypesOutputFolder();
            cachedNamespaceSpec = fullfile(generatedTypesOutputFolder, ...
                "namespaces", "ndx-photostim.mat");
            delete(cachedNamespaceSpec)
            
            % Test that warning for missing namespace works
            testCase.verifyWarning(...
                @() nwbExport(nwb, nwbFilePath), ...
                'NWB:validators:MissingEmbeddedNamespace')
        end

        function testExportFileWithStringDataType(testCase)
            nwb = tests.factory.NWBFile();

            generalExperimenter = ["John Doe", "Jane Doe"];
            generalExperimentDescription = "Test with string data types";
            nwb.general_experimenter = generalExperimenter;
            nwb.general_experiment_description = generalExperimentDescription;

            ts = tests.factory.TimeSeriesWithTimestamps();
            ts.comments = "String comment";
            ts.data_unit = "test";

            nwb.acquisition.set("TimeSeries", ts);
            nwbFilename = testCase.getRandomFilename();
            nwbExport(nwb, nwbFilename);

            nwbIn = nwbRead(nwbFilename, 'ignorecache');

            testCase.assertEqual( ...
                string( nwbIn.general_experimenter.load())', ...
                generalExperimenter)

            testCase.assertEqual( ...
                string(nwbIn.general_experiment_description)', ...
                generalExperimentDescription)

            tsIn = nwbIn.acquisition.get("TimeSeries");
                     
            testCase.assertEqual( ...
                string(tsIn.comments), ...
                ts.comments)

            testCase.assertEqual( ...
                string(tsIn.data_unit), ...
                ts.data_unit)
        end
    end
end
