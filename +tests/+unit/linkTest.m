classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...        
    linkTest < matlab.unittest.TestCase

    methods (TestMethodSetup)
        function setupMethod(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testExternLinkConstructor(testCase)
            l = types.untyped.ExternalLink('myfile.nwb', '/mypath');
            testCase.verifyEqual(l.path, '/mypath');
            testCase.verifyEqual(l.filename, 'myfile.nwb');
        end

        function testExternLinkConstructorWithBasePath(testCase)
            link = types.untyped.ExternalLink('myfile.nwb', '/mypath', 'somefolder');
            testCase.verifyEqual(link.BasePath, 'somefolder');
        end

        function testSoftLinkConstructor(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            testCase.applyFixture(SuppressedWarningsFixture('NWB:SoftLink:DeprecatedPath'));
            
            l = types.untyped.SoftLink('/mypath');
            testCase.verifyEqual(l.path, '/mypath');
        end

        function testSoftLinkPathDeprecated(testCase)
            testCase.verifyWarning(...
                @() types.untyped.SoftLink('/mypath'), ...
                'NWB:SoftLink:DeprecatedPath')
        end

        function testLinkExportSoft(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            testCase.applyFixture(SuppressedWarningsFixture('NWB:SoftLink:DeprecatedPath'));

            fid = H5F.create('test.nwb');
            close = onCleanup(@()H5F.close(fid));
            l = types.untyped.SoftLink('/mypath');
            l.export(fid, 'l1');
            info = h5info('test.nwb');
            testCase.verifyEqual(info.Links.Name, 'l1');
            testCase.verifyEqual(info.Links.Type, 'soft link');
            testCase.verifyEqual(info.Links.Value, {'/mypath'});
        end
        
        function testLinkExportExternal(testCase)
            fid = H5F.create('test.nwb');
            close = onCleanup(@()H5F.close(fid));
            l = types.untyped.ExternalLink('extern.nwb', '/mypath');
            l.export(fid, 'l1');
            info = h5info('test.nwb');
            testCase.verifyEqual(info.Links.Name, 'l1');
            testCase.verifyEqual(info.Links.Type, 'external link');
            testCase.verifyEqual(info.Links.Value, {'extern.nwb';'/mypath'});
        end
        
        function testExternalLinkExportImport(testCase)
            nwb = tests.factory.NWBFile();
            ts = tests.factory.TimeSeriesWithTimestamps();
            ts.data = types.untyped.ExternalLink('myfile.nwb', '/mypath');
            nwb.acquisition.set('timeseries_with_external_data', ts);
            fileName = 'external_link_export_import.nwb';
            nwbExport(nwb, fileName)
            
            nwbIn = nwbRead(fileName, 'ignorecache');
            tsIn = nwbIn.acquisition.get('timeseries_with_external_data');
            testCase.assertClass(tsIn.data, 'types.untyped.ExternalLink')
        end

        function testSoftResolution(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            testCase.applyFixture(SuppressedWarningsFixture('NWB:SoftLink:DeprecatedPath'));
            
            nwb = NwbFile;
            dev = types.core.Device;
            nwb.general_devices.set('testDevice', dev);
            nwb.general_extracellular_ephys.set('testEphys',...
                types.core.ElectrodeGroup('device',...
                types.untyped.SoftLink('/general/devices/testDevice')));
            testCase.verifyEqual(dev,...
                nwb.general_extracellular_ephys.get('testEphys').device.deref(nwb));
        end
        
        function testExternalResolution(testCase)
            nwb = NwbFile('identifier', 'EXTERNAL',...
                'session_description', 'external link test',...
                'session_start_time', datetime());
            
            expectedData = rand(100,1);
            stubDtr = types.hdmf_common.DynamicTableRegion(...
                'table', types.untyped.ObjectView('/acquisition/es1'),...
                'data', 1, ...
                'description', 'dtr stub that points to electrical series illegally'); % do not do this at home.
            expected = types.core.ElectricalSeries('data', expectedData,...
                'data_unit', 'volts', ...
                'timestamps', (1:100)', ...
                'electrodes', stubDtr);
            nwb.acquisition.set('es1', expected);
            nwb.export('test1.nwb');
            
            externalLink = types.untyped.ExternalLink('test1.nwb', '/acquisition/es1');
            tests.util.verifyContainerEqual(testCase, externalLink.deref(), expected);
            externalDataLink = types.untyped.ExternalLink('test1.nwb', '/acquisition/es1/data');
            % for datasets, a Datastub is returned.
            testCase.verifyEqual(externalDataLink.deref().load(), expectedData);
            
            nwb.acquisition.clear();
            nwb.acquisition.set('lfp', types.core.LFP('eslink', externalLink));
            nwb.export('test2.nwb');
            
            metaExternalLink = types.untyped.ExternalLink('test2.nwb', '/acquisition/lfp/eslink');
            % for links, deref() should return its own link.
            tests.util.verifyContainerEqual(testCase, metaExternalLink.deref().deref(), expected);
        end

        function testExternalResolutionToTypedDataset(testCase)
            % A link to a dataset that is itself a neurodata type, or that
            % holds object references, is parsed rather than returned as a
            % bare stub -- the branch testExternalResolution does not reach,
            % since it links to a plain dataset.
            nwb = NwbFile('identifier', 'TYPEDDATASET',...
                'session_description', 'external link to a typed dataset',...
                'session_start_time', datetime());
            tests.factory.ElectrodeTable(nwb);
            nwb.export('typed_dataset.nwb');

            % A typed dataset comes back as its neurodata type.
            idLink = types.untyped.ExternalLink('typed_dataset.nwb', ...
                '/general/extracellular_ephys/electrodes/id');
            identifiers = idLink.deref();
            testCase.verifyClass(identifiers, 'types.hdmf_common.ElementIdentifiers');
            testCase.verifyEqual(identifiers.data.load(), ...
                nwb.general_extracellular_ephys_electrodes.id.data);

            % A dataset of object references has those references resolved,
            % rather than being handed back as raw reference values.
            groupLink = types.untyped.ExternalLink('typed_dataset.nwb', ...
                '/general/extracellular_ephys/electrodes/group');
            groupColumn = groupLink.deref();
            testCase.verifyClass(groupColumn, 'types.hdmf_common.VectorData');
            testCase.verifyClass(groupColumn.data, 'types.untyped.ObjectView');
            testCase.verifyEqual({groupColumn.data.path}, ...
                {'/general/extracellular_ephys/ElectrodeGroup'});
        end

        function testExternalLinkRelativeTargetResolution(testCase)
            % A relative link target resolves against the folder containing
            % the linking file, matching HDF5 semantics, not against the
            % working directory. A decoy file with the target's name is
            % placed in the working directory: resolving against the wrong
            % base would silently return the decoy's data.
            dataFolder = fullfile(pwd, 'data');
            mkdir(dataFolder)

            expectedData = (1:10)';
            rawNwbFile = tests.factory.NWBFile();
            timeSeries = tests.factory.TimeSeriesWithTimestamps();
            timeSeries.data = expectedData;
            rawNwbFile.acquisition.set('ts', timeSeries);
            nwbExport(rawNwbFile, fullfile(dataFolder, 'raw.nwb'));

            decoyNwbFile = tests.factory.NWBFile();
            decoyTimeSeries = tests.factory.TimeSeriesWithTimestamps();
            decoyTimeSeries.data = -expectedData;
            decoyNwbFile.acquisition.set('ts', decoyTimeSeries);
            nwbExport(decoyNwbFile, 'raw.nwb');

            processedNwbFile = tests.factory.NWBFile();
            processedNwbFile.acquisition.set('linked', ...
                types.untyped.ExternalLink('raw.nwb', '/acquisition/ts'));
            nwbExport(processedNwbFile, fullfile(dataFolder, 'proc.nwb'));

            importedNwbFile = nwbRead(fullfile(dataFolder, 'proc.nwb'), 'ignorecache');
            % An unresolvable link fails type validation during nwbRead and
            % is dropped from the set, so its presence is asserted first.
            testCase.assertTrue(any(strcmp(importedNwbFile.acquisition.keys(), 'linked')), ...
                'The external link entry was dropped during nwbRead.')
            linkedSeries = importedNwbFile.acquisition.get('linked').deref();
            testCase.verifyEqual(linkedSeries.data.load(), expectedData);
        end

        function testExternalLinkAbsoluteTargetResolution(testCase)
            % An absolute link target must be used as given, unaffected by
            % the base captured from the linking file's folder.
            dataFolder = fullfile(pwd, 'data');
            mkdir(dataFolder)

            expectedData = (1:10)';
            rawNwbFile = tests.factory.NWBFile();
            timeSeries = tests.factory.TimeSeriesWithTimestamps();
            timeSeries.data = expectedData;
            rawNwbFile.acquisition.set('ts', timeSeries);
            rawFilePath = fullfile(pwd, 'raw.nwb');
            nwbExport(rawNwbFile, rawFilePath);

            processedNwbFile = tests.factory.NWBFile();
            processedNwbFile.acquisition.set('linked', ...
                types.untyped.ExternalLink(rawFilePath, '/acquisition/ts'));
            nwbExport(processedNwbFile, fullfile(dataFolder, 'proc.nwb'));

            importedNwbFile = nwbRead(fullfile(dataFolder, 'proc.nwb'), 'ignorecache');
            linkedSeries = importedNwbFile.acquisition.get('linked').deref();
            testCase.verifyEqual(linkedSeries.data.load(), expectedData);
        end

        function testExternalLinkChainedRelativeTarget(testCase)
            % Dereferencing a link whose target is itself an external link
            % returns a new ExternalLink; its relative target must resolve
            % against the folder of the file that chained link lives in.
            dataFolder = fullfile(pwd, 'data');
            mkdir(dataFolder)

            expectedData = (1:10)';
            rawNwbFile = tests.factory.NWBFile();
            timeSeries = tests.factory.TimeSeriesWithTimestamps();
            timeSeries.data = expectedData;
            rawNwbFile.acquisition.set('ts', timeSeries);
            nwbExport(rawNwbFile, fullfile(dataFolder, 'raw.nwb'));

            % A bare HDF5 file is enough to hold the intermediate link.
            writer = io.backend.hdf5.HDF5Writer(...
                fullfile(dataFolder, 'mid.nwb'), 'overwrite');
            writer.writeExternalLink('/elink', 'raw.nwb', '/acquisition/ts');
            writer.close();

            outerLink = types.untyped.ExternalLink(...
                fullfile(dataFolder, 'mid.nwb'), '/elink');
            chainedLink = outerLink.deref();
            testCase.assertClass(chainedLink, 'types.untyped.ExternalLink')
            testCase.verifyEqual(chainedLink.deref().data.load(), expectedData);
        end

        function testDirectTypeAssignmentToSoftLinkProperty(testCase)
            device = types.core.Device('description', 'test_device');
            electrodeGroup = types.core.ElectrodeGroup(...
                'description', 'test_group', ...
                'device', device);
        
            testCase.verifyClass(electrodeGroup.device, 'types.untyped.SoftLink')
            testCase.verifyClass(electrodeGroup.device.target, 'types.core.Device')
        end
        
        function testWrongTypeInSoftLinkAssignment(testCase)
            % Adding an OpticalChannel as device for ElectrodeGroup should fail.
            function createElectrodeGroupWithWrongDeviceType()
                not_a_device = types.core.OpticalChannel('description', 'test_channel');
                electrodeGroup = types.core.ElectrodeGroup(...
                    'description', 'test_group', ...
                    'device', not_a_device); %#ok<NASGU>
            end
            testCase.verifyError(@createElectrodeGroupWithWrongDeviceType, ...
                'NWB:CheckType:InvalidNeurodataType')
        end
                
        function testWrongTypeInSoftLinkTarget(testCase)
            % Adding an OpticalChannel as device for ElectrodeGroup should fail.
            function createElectrodeGroupWithWrongDeviceType()
                not_a_device = types.core.OpticalChannel('description', 'test_channel');
                electrodeGroup = types.core.ElectrodeGroup(...
                    'description', 'test_group', ...
                    'device', types.untyped.SoftLink(not_a_device)); %#ok<NASGU>
            end
            testCase.verifyError(@createElectrodeGroupWithWrongDeviceType, ...
                'NWB:CheckType:InvalidNeurodataType')
        end
        
        function testHardLinkCreationAndRead(testCase)
            % Test creating a hard link by converting a soft link using low-level H5 functions
            fileName = 'test_hardlink.nwb';
            
            % Create NWB file with a device and electrode group using soft link
            nwb = tests.factory.NWBFile();
            dev = types.core.Device('description', 'device for hard link test');
            nwb.general_devices.set('testDevice', dev);
            nwb.general_extracellular_ephys.set('testEphys',...
                types.core.ElectrodeGroup(...
                    'device', types.untyped.SoftLink(dev), ...
                    'description', 'test with hard link', ...
                    'location', 'n/a') ...
            );
            
            % Export the NWB file
            nwbExport(nwb, fileName);
            
            % Use helper method to replace the soft link with a hard link
            softLinkPath = '/general/extracellular_ephys/testEphys/device';
            targetPath = '/general/devices/testDevice';
            testCase.replaceSoftLinkWithHardLink(fileName, softLinkPath, targetPath)

            % Verify the hard link was created correctly using h5info
            fileInfoAfter = h5info(fileName, "/general"); 
            isEphysGroup = strcmp({fileInfoAfter.Groups.Name}, '/general/extracellular_ephys');
            ephysInfo = fileInfoAfter.Groups(isEphysGroup);
            testCase.verifyTrue( strcmp(ephysInfo.Groups.Links.Type, 'hard link') )

            % Verify it behaves like a hard link by reading it directly 
            % (it should appear as a group, not a link);
            info = h5info(fileName, '/general/extracellular_ephys/testEphys');
            testCase.verifyTrue( endsWith(info.Groups.Name, 'device'), ...
                'Hard link should appear as a group reference' )
            
            % Read the file back with nwbRead and verify it works
            nwbReadResult = nwbRead(fileName, 'ignorecache');
            testCase.verifyClass(nwbReadResult, 'NwbFile', ...
                'Should be able to read the file as an NWB file');
            
            % Verify the electrode group is still accessible
            readEphys = nwbReadResult.general_extracellular_ephys.get('testEphys');
            testCase.verifyClass(readEphys, 'types.core.ElectrodeGroup', ...
                'ElectrodeGroup should be readable');
            
            % Verify the device reference still works (hard link should be transparent)
            readDevice = readEphys.device;
            testCase.verifyClass(readDevice, 'types.untyped.SoftLink', ...
                'Hard links will be treated using SoftLink type')
            
            % Verify it can be dereferenced
            actualDevice = readDevice.deref(nwbReadResult);
            testCase.verifyClass(actualDevice, 'types.core.Device', ...
                'Device should be accessible through hard link');
        end
    end

    methods (Static, Access=private)
        function replaceSoftLinkWithHardLink(fileName, softLinkPath, targetPath)
            % Use low-level H5 functions to replace a soft link with a hard link
            fid = H5F.open(fileName, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
            closeFile = onCleanup(@()H5F.close(fid));
            
            % Delete the existing soft link
            H5L.delete(fid, softLinkPath, 'H5P_DEFAULT');
            
            % Create a hard link to replace it
            H5L.create_hard(fid, targetPath, fid, softLinkPath, ...
                'H5P_DEFAULT', 'H5P_DEFAULT');
            
            % Close the file
            clear closeFile;
        end
    end
end

