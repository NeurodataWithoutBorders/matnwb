classdef HDF5ReaderTest < matlab.unittest.TestCase

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function canOpenOnlyHDF5Files(testCase)
            h5create("probe.h5", "/data", 1);
            fileId = fopen("probe.txt", "w");
            fprintf(fileId, "not an HDF5 file");
            fclose(fileId);
            mkdir("probe-folder")

            testCase.verifyTrue(io.backend.hdf5.HDF5Reader.canOpen("probe.h5"));
            testCase.verifyFalse(io.backend.hdf5.HDF5Reader.canOpen("probe.txt"));
            testCase.verifyFalse(io.backend.hdf5.HDF5Reader.canOpen("probe-folder"));
            testCase.verifyFalse(io.backend.hdf5.HDF5Reader.canOpen("missing.h5"));
        end

        function readRootAndSchemaVersion(testCase)
            nwb = tests.factory.NWBFile();
            filename = "reader-test.nwb";
            nwbExport(nwb, filename);

            reader = io.backend.hdf5.HDF5Reader(filename);
            rootInfo = reader.readRootInfo();

            testCase.verifyClass(rootInfo, 'io.backend.model.GroupInfo');
            testCase.verifyEqual(rootInfo.Path, '/');
            testCase.verifyEqual(reader.getSchemaVersion(), util.getSchemaVersion(filename));
        end

        function readRootInfoDescribesHierarchy(testCase)
            writer = io.backend.hdf5.HDF5Writer("reader-hierarchy.nwb", "overwrite");
            writer.writeGroup('/group');
            writer.writeAttribute('/group/label', 'a group');
            writer.writeValue('/group/values', [1 2 3]);
            writer.writeAttribute('/group/values/unit', 'volts');
            writer.writeSoftLink('/group/soft', '/group/values');
            writer.writeExternalLink('/group/external', 'other.nwb', '/data');
            writer.close();

            reader = io.backend.hdf5.HDF5Reader("reader-hierarchy.nwb");
            rootInfo = reader.readRootInfo();

            groupInfo = rootInfo.Groups;
            testCase.verifyEqual(groupInfo.Path, '/group');
            testCase.verifyEqual(groupInfo.Name, 'group');
            testCase.verifyEqual(groupInfo.Attributes.Name, 'label');
            testCase.verifyEqual(groupInfo.Attributes.Value, 'a group');

            datasetInfo = groupInfo.Datasets;
            testCase.verifyEqual(datasetInfo.Name, 'values');
            testCase.verifyEqual(datasetInfo.Attributes.Name, 'unit');
            testCase.verifyEqual(datasetInfo.Attributes.Value, 'volts');

            [~, order] = sort({groupInfo.Links.Name});
            links = groupInfo.Links(order);
            testCase.verifyEqual({links.Name}, {'external', 'soft'});
            testCase.verifyEqual({links.Type}, {'external link', 'soft link'});
            testCase.verifyEqual({links.TargetPath}, {'/data', '/group/values'});
            testCase.verifyEqual({links.TargetFile}, {'other.nwb', ''});
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

        function readNodeInfoDescribesSoftLinkWithoutFollowingIt(testCase)
            writer = io.backend.hdf5.HDF5Writer("reader-softlink.nwb", "overwrite");
            writer.writeGroup('/target');
            writer.writeSoftLink('/link', '/target');
            writer.close();

            reader = io.backend.hdf5.HDF5Reader("reader-softlink.nwb");
            linkInfo = reader.readNodeInfo("/link");

            testCase.verifyClass(linkInfo, 'io.backend.model.LinkInfo');
            testCase.verifyEqual(linkInfo.Name, 'link');
            testCase.verifyEqual(linkInfo.Type, 'soft link');
            testCase.verifyEqual(linkInfo.TargetPath, '/target');
            testCase.verifyEqual(linkInfo.TargetFile, '');
        end

        function readNodeInfoDescribesExternalLink(testCase)
            writer = io.backend.hdf5.HDF5Writer("reader-external.nwb", "overwrite");
            writer.writeExternalLink('/elink', 'other.nwb', '/data');
            writer.close();

            reader = io.backend.hdf5.HDF5Reader("reader-external.nwb");
            linkInfo = reader.readNodeInfo("/elink");

            testCase.verifyClass(linkInfo, 'io.backend.model.LinkInfo');
            testCase.verifyEqual(linkInfo.Type, 'external link');
            testCase.verifyEqual(linkInfo.TargetFile, 'other.nwb');
            testCase.verifyEqual(linkInfo.TargetPath, '/data');
        end

        function readNodeInfoDescribesGroupAndDataset(testCase)
            writer = io.backend.hdf5.HDF5Writer("reader-nodes.nwb", "overwrite");
            writer.writeGroup('/plain');
            writer.writeValue('/plain/values', [1 2 3]);
            writer.close();

            reader = io.backend.hdf5.HDF5Reader("reader-nodes.nwb");

            groupInfo = reader.readNodeInfo("/plain");
            testCase.verifyClass(groupInfo, 'io.backend.model.GroupInfo');
            testCase.verifyEqual(groupInfo.Path, '/plain');

            datasetInfo = reader.readNodeInfo("/plain/values");
            testCase.verifyClass(datasetInfo, 'io.backend.model.DatasetInfo');
            testCase.verifyEqual(datasetInfo.Name, 'values');
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

            referenceInfo = reader.readNodeInfo( ...
                "/general/extracellular_ephys/electrodes/group");
            testCase.verifyTrue(reader.isReferenceDataset(referenceInfo));

            plainInfo = reader.readNodeInfo( ...
                "/general/extracellular_ephys/electrodes/group_name");
            testCase.verifyFalse(reader.isReferenceDataset(plainInfo));
        end

    end
end
