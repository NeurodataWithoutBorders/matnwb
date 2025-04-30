classdef NWBFileIOTest < tests.system.PyNWBIOTest

    methods
        function addContainer(testCase, file) %#ok<INUSL>
            ts = types.core.TimeSeries(...
                'data', int64(100:10:190) .', ...
                'data_unit', 'SIunit', ...
                'timestamps', (0:9) .', ...
                'data_resolution', 0.1);
            file.acquisition.set('test_timeseries', ts);
            spatialSeries = types.core.SpatialSeries( ...
                'description', 'A test spatial series', ...
                'data', int64((1:10))' , ...
                'data_unit', 'n/a', ...
                'timestamps', int64((1:10))');

            mod = types.core.ProcessingModule( ...
                'description', 'a test module', ...
                'SpatialSeries', spatialSeries);
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

        function testLoadAll(testCase)
            fileName = ['MatNWB.' testCase.className() '.testLoadAll.nwb'];
            nwbExport(testCase.file, fileName)
            nwb = nwbRead(fileName, "ignorecache");            
            nwb.loadAll();
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

            io.internal.h5.deleteGroup(fileName, 'specifications')

            nwbRead(fileName, "ignorecache");
        end

        function readFileWithoutSpecLoc(testCase)
             
            fileName = ['MatNWB.' testCase.className() '.testReadFileWithoutSpecLoc.nwb'];
            nwbExport(testCase.file, fileName)

            io.internal.h5.deleteAttribute(fileName, '/', '.specloc')

            % When specloc is missing, the specifications are not added to
            % the blacklist, so it will get passed as an input to NwbFile.
            testCase.verifyError(@(fn) nwbRead(fileName, "ignorecache"), 'MATLAB:TooManyInputs');
        end

        function readFileWithUnsupportedVersion(testCase)
            fileName = ['MatNWB.' testCase.className() '.testReadFileWithUnsupportedVersion.nwb'];
            nwbExport(testCase.file, fileName)

            io.internal.h5.deleteAttribute(fileName, '/', 'nwb_version')
            
            file_id = H5F.open(fileName, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
            io.writeAttribute(file_id, '/nwb_version', '1.0.0')
            H5F.close(file_id);

            testCase.verifyWarning(@(fn) nwbRead(fileName, "ignorecache"), 'NWB:Read:UnsupportedSchema')
        end

        function readFileWithUnsupportedVersionAndNoSpecloc(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            testCase.applyFixture(SuppressedWarningsFixture('NWB:Read:UnsupportedSchema'))

            fileName = ['MatNWB.' testCase.className() '.testReadFileWithUnsupportedVersionAndNoSpecloc.nwb'];
            nwbExport(testCase.file, fileName)
            
            io.internal.h5.deleteAttribute(fileName, '/', '.specloc')
            io.internal.h5.deleteAttribute(fileName, '/', 'nwb_version')
            
            file_id = H5F.open(fileName, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
            io.writeAttribute(file_id, '/nwb_version', '1.0.0')
            H5F.close(file_id);

            % When specloc is missing, the specifications are not added to
            % the blacklist, so it will get passed as an input to NwbFile.
            testCase.verifyError(@(fn) nwbRead(fileName, "ignorecache"), 'MATLAB:TooManyInputs');
        end
    end
end
