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

        function getExternalLinkBaseReturnsFileFolder(testCase)
            writer = io.backend.hdf5.HDF5Writer("reader-linkbase.nwb", "overwrite");
            writer.close();

            reader = io.backend.hdf5.HDF5Reader("reader-linkbase.nwb");
            % The base must be the absolute path of the containing folder;
            % fileattrib is used for the expected value as well so symlinked
            % temp folders (e.g. /var -> /private/var on macOS) compare equal.
            [~, folderInfo] = fileattrib(pwd);
            testCase.verifyEqual(reader.getExternalLinkBase(), string(folderInfo.Name));
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

            testCase.verifyEqual(linkInfo.type, "soft link");
            testCase.verifyEqual(linkInfo.targetPath, "/target");
            testCase.verifyEqual(linkInfo.targetFilename, "");
        end

        function readLinkInfoReturnsExternalLinkTarget(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture);

            writer = io.backend.hdf5.HDF5Writer("reader-external.nwb", "overwrite");
            writer.writeExternalLink('/elink', 'other.nwb', '/data');
            writer.close();

            reader = io.backend.hdf5.HDF5Reader("reader-external.nwb");
            linkInfo = reader.readLinkInfo("/elink");

            testCase.verifyEqual(linkInfo.type, "external link");
            testCase.verifyEqual(linkInfo.targetFilename, "other.nwb");
            testCase.verifyEqual(linkInfo.targetPath, "/data");
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


        function isReferenceDatasetIdentifiesReferenceDatasets(testCase)
        % ExternalLink.deref routes a dataset either through io.parseDataset
        % or into a plain DataStub, and needs to know whether the dataset
        % holds references to choose. The encoding of that is the backend's
        % business, so the reader answers rather than the caller inspecting
        % HDF5 datatype classes.
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture);

            nwb = NwbFile('identifier', 'REF', 'session_description', 'ref', ...
                'session_start_time', datetime(2026, 1, 1, 'TimeZone', 'local'));
            % An electrodes table gives a "group" column of object references.
            tests.factory.ElectrodeTable(nwb);
            nwbExport(nwb, 'reference-probe.nwb');

            reader = io.backend.hdf5.HDF5Reader('reference-probe.nwb');

            referenceInfo = h5info('reference-probe.nwb', ...
                '/general/extracellular_ephys/electrodes/group');
            testCase.verifyTrue(reader.isReferenceDataset(referenceInfo));

            plainInfo = h5info('reference-probe.nwb', ...
                '/general/extracellular_ephys/electrodes/group_name');
            testCase.verifyFalse(reader.isReferenceDataset(plainInfo));
        end

    end
end
