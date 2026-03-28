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
            rootInfo = reader.readRoot();

            testCase.verifyEqual(rootInfo.Name, "/");
            testCase.verifyEqual(reader.getSchemaVersion(), util.getSchemaVersion(filename));
        end

        function processDatasetInfoReturnsDataStubForScalarDataset(testCase)
            nwb = tests.factory.NWBFile();
            filename = "reader-dataset-test.nwb";
            nwbExport(nwb, filename);

            reader = io.backend.hdf5.HDF5Reader(filename);
            rootInfo = reader.readRoot();
            datasetInfo = rootInfo.Datasets(strcmp({rootInfo.Datasets.Name}, "session_start_time"));
            datasetValue = reader.processDatasetInfo(datasetInfo, "/session_start_time");

            testCase.verifyClass(datasetValue, "types.untyped.DataStub");
        end
    end
end
