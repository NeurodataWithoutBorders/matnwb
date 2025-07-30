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

        function testSoftLinkConstructor(testCase)
            l = types.untyped.SoftLink('/mypath');
            testCase.verifyEqual(l.path, '/mypath');
        end
        
        function testLinkExportSoft(testCase)
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
            
            nwbIn = nwbRead(fileName);
            tsIn = nwbIn.acquisition.get('timeseries_with_external_data');
            testCase.assertClass(tsIn.data, 'types.untyped.ExternalLink')
        end

        function testSoftResolution(testCase)
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
                'NWB:CheckDType:InvalidNeurodataType')
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
            nwbReadResult = nwbRead(fileName);
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

