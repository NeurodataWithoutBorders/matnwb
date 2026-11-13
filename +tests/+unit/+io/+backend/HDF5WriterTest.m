classdef HDF5WriterTest < matlab.unittest.TestCase

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function deleteGroupDeletesPopulatedGroup(testCase)
            writer = io.backend.hdf5.HDF5Writer("writer-test.nwb", "overwrite");
            testCase.addTeardown(@() writer.close());
            writer.writeGroup('/specifications/core');
            writer.writeValue('/specifications/core/namespace', 'schema');

            writer.deleteGroup('/specifications/core');

            groupExists = H5L.exists(writer.H5FileId, ...
                '/specifications/core', 'H5P_DEFAULT');
            testCase.verifyFalse(logical(groupExists));
        end

        function writeSoftLinkCreatesSoftLink(testCase)
            writer = io.backend.hdf5.HDF5Writer("softlink-test.nwb", "overwrite");
            testCase.addTeardown(@() writer.close());
            writer.writeGroup('/target');

            writer.writeSoftLink('/link', '/target');
            writer.close();

            info = h5info("softlink-test.nwb", '/');
            link = info.Links(strcmp({info.Links.Name}, 'link'));
            testCase.verifyEqual(link.Type, 'soft link');
            testCase.verifyEqual(link.Value{1}, '/target');
        end

        function writeSoftLinkIsIdempotent(testCase)
        % Re-exporting an object whose link target was not resolvable on the
        % first pass writes the same link again (see
        % NwbFile.resolveReferences), so rewriting an identical link must
        % succeed rather than collide.
            writer = io.backend.hdf5.HDF5Writer("resoftlink-test.nwb", "overwrite");
            testCase.addTeardown(@() writer.close());
            writer.writeGroup('/target');

            writer.writeSoftLink('/link', '/target');
            testCase.verifyWarningFree(@() writer.writeSoftLink('/link', '/target'));
            writer.close();

            info = h5info("resoftlink-test.nwb", '/');
            link = info.Links(strcmp({info.Links.Name}, 'link'));
            testCase.verifyEqual(link.Value{1}, '/target');
        end

        function writeSoftLinkReplacesDifferentTarget(testCase)
            writer = io.backend.hdf5.HDF5Writer("relink-test.nwb", "overwrite");
            testCase.addTeardown(@() writer.close());
            writer.writeGroup('/first');
            writer.writeGroup('/second');

            writer.writeSoftLink('/link', '/first');
            writer.writeSoftLink('/link', '/second');
            writer.close();

            info = h5info("relink-test.nwb", '/');
            link = info.Links(strcmp({info.Links.Name}, 'link'));
            testCase.verifyEqual(link.Value{1}, '/second');
        end

        function writeExternalLinkIsIdempotent(testCase)
        % The external branch of the existing-link comparison: re-writing an
        % identical external link leaves it alone rather than deleting and
        % recreating it, matching the soft-link case.
            writer = io.backend.hdf5.HDF5Writer("re-external-test.nwb", "overwrite");
            testCase.addTeardown(@() writer.close());

            writer.writeExternalLink('/elink', 'other.nwb', '/data');
            testCase.verifyWarningFree(...
                @() writer.writeExternalLink('/elink', 'other.nwb', '/data'));
            writer.close();

            info = h5info("re-external-test.nwb", '/');
            link = info.Links(strcmp({info.Links.Name}, 'elink'));
            testCase.verifyEqual(link.Value, {'other.nwb'; '/data'});
        end

        function writeExternalLinkReplacesDifferentTarget(testCase)
        % An external link differing in either the file or the path is a
        % different link, so it replaces the one already there. Both halves
        % of the comparison are exercised.
            writer = io.backend.hdf5.HDF5Writer("swap-external-test.nwb", "overwrite");
            testCase.addTeardown(@() writer.close());

            writer.writeExternalLink('/elink', 'first.nwb', '/data');
            writer.writeExternalLink('/elink', 'second.nwb', '/data');
            writer.writeExternalLink('/pathlink', 'same.nwb', '/first');
            writer.writeExternalLink('/pathlink', 'same.nwb', '/second');
            writer.close();

            info = h5info("swap-external-test.nwb", '/');
            changedFile = info.Links(strcmp({info.Links.Name}, 'elink'));
            changedPath = info.Links(strcmp({info.Links.Name}, 'pathlink'));
            testCase.verifyEqual(changedFile.Value, {'second.nwb'; '/data'});
            testCase.verifyEqual(changedPath.Value, {'same.nwb'; '/second'});
        end

        function writeLinkRejectsPathHeldByAnotherNode(testCase)
        % A group or dataset at the link path is not something to compare or
        % replace -- H5L.get_val is not even valid for it. Report the
        % conflict rather than deleting the node that is already there.
            writer = io.backend.hdf5.HDF5Writer("occupied-test.nwb", "overwrite");
            testCase.addTeardown(@() writer.close());
            writer.writeGroup('/occupied');

            testCase.verifyError(@() writer.writeSoftLink('/occupied', '/elsewhere'), ...
                'NWB:WriteLink:PathOccupiedByNode');
            testCase.verifyError(...
                @() writer.writeExternalLink('/occupied', 'other.nwb', '/data'), ...
                'NWB:WriteLink:PathOccupiedByNode');

            % The group that was already there must survive the rejected writes.
            writer.close();
            info = h5info("occupied-test.nwb", '/');
            testCase.verifyTrue(any(endsWith({info.Groups.Name}, 'occupied')));
        end

        function writeSoftLinkReplacesExternalLinkAtSamePath(testCase)
        % Two links of different kinds at one path are both links, so the
        % newer one replaces the older rather than being a conflict.
            writer = io.backend.hdf5.HDF5Writer("swap-test.nwb", "overwrite");
            testCase.addTeardown(@() writer.close());
            writer.writeGroup('/target');

            writer.writeExternalLink('/link', 'other.nwb', '/data');
            writer.writeSoftLink('/link', '/target');
            writer.close();

            info = h5info("swap-test.nwb", '/');
            link = info.Links(strcmp({info.Links.Name}, 'link'));
            testCase.verifyEqual(link.Type, 'soft link');
            testCase.verifyEqual(link.Value{1}, '/target');
        end

        function writeExternalLinkRecordsFileAndPath(testCase)
            targetWriter = io.backend.hdf5.HDF5Writer("target-file.nwb", "overwrite");
            targetWriter.writeGroup('/data');
            targetWriter.close();

            writer = io.backend.hdf5.HDF5Writer("external-test.nwb", "overwrite");
            testCase.addTeardown(@() writer.close());
            writer.writeExternalLink('/elink', 'target-file.nwb', '/data');
            writer.close();

            info = h5info("external-test.nwb", '/');
            link = info.Links(strcmp({info.Links.Name}, 'elink'));
            testCase.verifyEqual(link.Type, 'external link');
            testCase.verifyEqual(link.Value, {'target-file.nwb'; '/data'});
        end
    end
end
