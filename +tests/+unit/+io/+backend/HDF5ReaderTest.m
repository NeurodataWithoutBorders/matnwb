classdef HDF5ReaderTest < matlab.unittest.TestCase

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function readRootAndSchemaVersion(testCase)
            nwb = tests.factory.NWBFile();
            filename = "reader-test.nwb";
            nwbExport(nwb, filename);

            reader = io.backend.hdf5.HDF5Reader(filename);
            rootInfo = reader.readRootInfo();

            testCase.verifyEqual(rootInfo.Name, '/');
            testCase.verifyEqual(reader.getSchemaVersion(), util.getSchemaVersion(filename));
        end

        function readDatasetValueReadsScalarDatasetEagerly(testCase)
            nwb = tests.factory.NWBFile();
            filename = "reader-dataset-test.nwb";
            nwbExport(nwb, filename);

            reader = io.backend.hdf5.HDF5Reader(filename);
            rootInfo = reader.readRootInfo();
            datasetInfo = rootInfo.Datasets(strcmp({rootInfo.Datasets.Name}, "session_start_time"));
            datasetValue = reader.readDatasetValue(datasetInfo, "/session_start_time");

            testCase.verifyFalse(isa(datasetValue, "types.untyped.DataStub"))
        end

        function readLinkInfoReturnsSoftLinkTarget(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture);

            writer = io.backend.hdf5.HDF5Writer("reader-softlink.nwb", "overwrite");
            writer.writeGroup('/target');
            writer.writeSoftLink('/link', '/target');
            writer.close();

            reader = io.backend.hdf5.HDF5Reader("reader-softlink.nwb");
            linkInfo = reader.readLinkInfo("/link");

            testCase.verifyEqual(linkInfo.Type, "soft link");
            testCase.verifyEqual(linkInfo.TargetPath, "/target");
            testCase.verifyEqual(linkInfo.TargetFilename, "");
        end

        function readLinkInfoReturnsExternalLinkTarget(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture);

            writer = io.backend.hdf5.HDF5Writer("reader-external.nwb", "overwrite");
            writer.writeExternalLink('/elink', 'other.nwb', '/data');
            writer.close();

            reader = io.backend.hdf5.HDF5Reader("reader-external.nwb");
            linkInfo = reader.readLinkInfo("/elink");

            testCase.verifyEqual(linkInfo.Type, "external link");
            testCase.verifyEqual(linkInfo.TargetFilename, "other.nwb");
            testCase.verifyEqual(linkInfo.TargetPath, "/data");
        end

        function readLinkInfoRejectsNodeThatIsNotALink(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture);

            writer = io.backend.hdf5.HDF5Writer("reader-nolink.nwb", "overwrite");
            writer.writeGroup('/plain');
            writer.close();

            reader = io.backend.hdf5.HDF5Reader("reader-nolink.nwb");

            testCase.verifyError(@() reader.readLinkInfo("/plain"), ...
                'NWB:Backend:Reader:UnsupportedLinkType');
        end

    end
end
