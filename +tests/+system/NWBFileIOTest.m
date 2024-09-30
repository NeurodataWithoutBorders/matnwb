classdef NWBFileIOTest < tests.system.PyNWBIOTest
    methods
        function addContainer(testCase, file) %#ok<INUSL>
            ts = types.core.TimeSeries(...
                'data', int64(100:10:190) .', ...
                'data_unit', 'SIunit', ...
                'timestamps', (0:9) .', ...
                'data_resolution', 0.1);
            file.acquisition.set('test_timeseries', ts);
            clust = types.core.Clustering( ...
                'description', 'A fake Clustering interface', ...
                'num', [0, 1, 2, 0, 1, 2] .', ...
                'peak_over_rms', [100, 101, 102] .', ...
                'times', (10:10:60) .');
            mod = types.core.ProcessingModule( ...
                'description', 'a test module', ...
                'Clustering', clust);
            file.processing.set('test_module', mod);
        end
        
        function c = getContainer(testCase, file) %#ok<INUSL>
            c = file;
        end
    end

    methods (Test)
        function writeMultipleFiles(testCase)
            
            fileA = testCase.file;
            fileB = NwbFile( ...
                'session_description', 'a second test NWB File', ...
                'identifier', 'TEST456', ...
                'session_start_time', '2018-12-02T12:57:27.371444-08:00', ...
                'file_create_date', '2017-04-15T12:00:00.000000-08:00',...
                'timestamps_reference_time', '2018-12-02T12:57:27.371444-08:00');
            
            fileNameA = ['MatNWB.' testCase.className() '.testWriteMultiA.nwb'];
            fileNameB = ['MatNWB.' testCase.className() '.testWriteMultiB.nwb'];

            nwbExport([fileA, fileB], {fileNameA, fileNameB});
        end

        function readWithStringArg(testCase)
            fileName = ['MatNWB.' testCase.className() '.testReadWithStringArg.nwb'];
            fileName = string(fileName);
            nwbExport(testCase.file, fileName)
            nwbRead(fileName, "ignorecache");
        end

        function readFileWithoutSpec(testCase)
            fileName = ['MatNWB.' testCase.className() '.testReadFileWithoutSpec.nwb'];
            nwbExport(testCase.file, fileName)

            testCase.deleteGroupFromFile(fileName, 'specifications')
            nwbRead(fileName);
        end

        function readFileWithoutSpecLoc(testCase)
            fileName = ['MatNWB.' testCase.className() '.testReadFileWithoutSpecLoc.nwb'];
            nwbExport(testCase.file, fileName)

            testCase.deleteAttributeFromFile(fileName, '/', '.specloc')

            nwbRead(fileName);
        end

        function readFileWithUnsupportedVersion(testCase)
            fileName = ['MatNWB.' testCase.className() '.testReadFileWithUnsupportedVersion.nwb'];
            nwbExport(testCase.file, fileName)

            testCase.deleteAttributeFromFile(fileName, '/', 'nwb_version')
            
            file_id = H5F.open(fileName, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
            io.writeAttribute(file_id, '/nwb_version', '1.0.0')
            H5F.close(file_id);

            nwbRead(fileName);
        end
    end

    methods (Static, Access = private)
        function deleteGroupFromFile(fileName, groupName)
            if ~startsWith(groupName, '/')
                groupName = ['/', groupName];
            end
            
            % Open the HDF5 file in read-write mode
            file_id = H5F.open(fileName, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
            
            % Delete the group
            H5L.delete(file_id, groupName, 'H5P_DEFAULT');
            
            % Close the HDF5 file
            H5F.close(file_id);
        end

        function deleteAttributeFromFile(fileName, objectName, attributeName)
            % Open the HDF5 file in read-write mode
            file_id = H5F.open(fileName, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
            
            % Open the object (dataset or group)
            object_id = H5O.open(file_id, objectName, 'H5P_DEFAULT');
            
            % Delete the attribute
            H5A.delete(object_id, attributeName);
            
            % Close the object
            H5O.close(object_id);
            
            % Close the HDF5 file
            H5F.close(file_id);
        end
    end
end

