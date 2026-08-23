classdef objectIdTest < tests.abstract.NwbTestCase
% objectIdTest - Unit tests for persistent object ids on neurodata types.
%
% Object ids are assigned once when a neurodata type object is constructed
% (adopting the id passed from file on read, generating a new UUID
% otherwise) and are reused verbatim on every export.

    properties (Constant)
        % 8-4-4-4-12 hexadecimal digits, the format produced by
        % java.util.UUID and expected by other NWB APIs.
        UuidPattern = '^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$'
    end

    methods (TestClassSetup)
        function setupTemporaryWorkingFolder(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testObjectIdAssignedOnConstruction(testCase)
            timeSeriesA = tests.factory.TimeSeries();
            timeSeriesB = tests.factory.TimeSeries();

            testCase.verifyMatches(timeSeriesA.object_id, testCase.UuidPattern);
            testCase.verifyMatches(timeSeriesB.object_id, testCase.UuidPattern);
            testCase.verifyNotEqual(timeSeriesA.object_id, timeSeriesB.object_id);
        end

        function testObjectIdSettableViaConstructor(testCase)
            uuid = '01234567-89ab-cdef-0123-456789abcdef';
            timeSeries = types.core.TimeSeries('object_id', uuid);
            testCase.verifyEqual(timeSeries.object_id, uuid);

            nwbFile = NwbFile('object_id', uuid);
            testCase.verifyEqual(nwbFile.object_id, uuid);
        end

        function testObjectIdIsReadOnly(testCase)
            timeSeries = tests.factory.TimeSeries();
            testCase.verifyError(...
                @() setfield(timeSeries, 'object_id', 'other'), ...
                'MATLAB:class:SetProhibited');
        end

        function testObjectIdStableAcrossExports(testCase)
            nwbFile = tests.factory.NWBFile();
            timeSeries = tests.factory.TimeSeries();
            nwbFile.acquisition.set('ts', timeSeries);

            filenameA = testCase.getRandomFilename();
            filenameB = testCase.getRandomFilename();
            nwbExport(nwbFile, filenameA);
            nwbExport(nwbFile, filenameB);

            for filename = {filenameA, filenameB}
                testCase.verifyEqual(...
                    h5readatt(filename{1}, '/', 'object_id'), nwbFile.object_id);
                testCase.verifyEqual(...
                    h5readatt(filename{1}, '/acquisition/ts', 'object_id'), ...
                    timeSeries.object_id);
            end
        end

        function testRoundTripPreservesObjectIds(testCase)
            nwbFile = tests.factory.NWBFile();
            nwbFile.acquisition.set('ts', tests.factory.TimeSeries());

            filenameA = testCase.getRandomFilename();
            nwbExport(nwbFile, filenameA);

            nwbFileIn = nwbRead(filenameA, 'ignorecache');
            testCase.verifyEqual(nwbFileIn.object_id, nwbFile.object_id);
            testCase.verifyEqual(...
                nwbFileIn.acquisition.get('ts').object_id, ...
                nwbFile.acquisition.get('ts').object_id);

            % Ids must also survive re-export of the read file to a new file.
            filenameB = testCase.getRandomFilename();
            nwbExport(nwbFileIn, filenameB);
            testCase.verifyEqual(...
                h5readatt(filenameB, '/', 'object_id'), nwbFile.object_id);
            testCase.verifyEqual(...
                h5readatt(filenameB, '/acquisition/ts', 'object_id'), ...
                nwbFile.acquisition.get('ts').object_id);
        end

        function testTypedDatasetObjectIdConsumedOnRead(testCase)
            % Regression test: object_id of a typed dataset (e.g. a
            % DynamicTable column) must be adopted by the typed object
            % itself, not promoted to the parent under an elided name
            % (e.g. 'id_object_id'), which also raised an unexpected
            % property warning on read.
            nwbFile = tests.factory.NWBFile();
            nwbFile.intervals_trials = tests.factory.TimeIntervals();

            filename = testCase.getRandomFilename();
            nwbExport(nwbFile, filename);

            nwbFileIn = testCase.verifyWarningFree(...
                @() nwbRead(filename, 'ignorecache'));

            trials = nwbFileIn.intervals_trials;
            testCase.verifyEqual(trials.object_id, ...
                h5readatt(filename, '/intervals/trials', 'object_id'));
            testCase.verifyEqual(trials.id.object_id, ...
                h5readatt(filename, '/intervals/trials/id', 'object_id'));
            testCase.verifyEqual(trials.start_time.object_id, ...
                h5readatt(filename, '/intervals/trials/start_time', 'object_id'));
        end

        function testFileWithoutObjectIdsIsAssignedNewIds(testCase)
            % Files written before object ids were introduced (NWB < 2.2)
            % have no object_id attributes. They must read cleanly, with
            % new ids assigned on construction.
            nwbFile = tests.factory.NWBFile();
            nwbFile.acquisition.set('ts', tests.factory.TimeSeries());

            filename = testCase.getRandomFilename();
            nwbExport(nwbFile, filename);
            io.internal.h5.deleteAttribute(filename, '/', 'object_id');
            io.internal.h5.deleteAttribute(filename, '/acquisition/ts', 'object_id');

            nwbFileIn = nwbRead(filename, 'ignorecache');
            testCase.verifyMatches(nwbFileIn.object_id, testCase.UuidPattern);
            testCase.verifyMatches(...
                nwbFileIn.acquisition.get('ts').object_id, testCase.UuidPattern);
        end

        function testGenerateNewObjectIdNonRecursive(testCase)
            trials = tests.factory.TimeIntervals();
            tableId = trials.object_id;
            columnId = trials.start_time.object_id;

            trials.generateNewObjectId('Recurse', false);
            testCase.verifyNotEqual(trials.object_id, tableId);
            testCase.verifyMatches(trials.object_id, testCase.UuidPattern);
            testCase.verifyEqual(trials.start_time.object_id, columnId);
        end

        function testGenerateNewObjectIdRecursesIntoContainedTypes(testCase)
            nwbFile = tests.factory.NWBFile();
            nwbFile.intervals_trials = tests.factory.TimeIntervals();
            timeSeries = tests.factory.TimeSeries();
            nwbFile.acquisition.set('ts', timeSeries);

            oldIds = {nwbFile.object_id, ...
                nwbFile.intervals_trials.object_id, ...
                nwbFile.intervals_trials.id.object_id, ...
                timeSeries.object_id};

            nwbFile.generateNewObjectId();

            newIds = {nwbFile.object_id, ...
                nwbFile.intervals_trials.object_id, ...
                nwbFile.intervals_trials.id.object_id, ...
                timeSeries.object_id};

            for i = 1:numel(oldIds)
                testCase.verifyNotEqual(newIds{i}, oldIds{i});
                testCase.verifyMatches(newIds{i}, testCase.UuidPattern);
            end
            testCase.verifyNumElements(unique(newIds), numel(newIds));
        end

        function testExportingOneObjectToTwoLocationsWarns(testCase)
            % An object id identifies a single object, so exporting the same
            % object to two locations would write two objects sharing one id
            % — a file PyNWB rejects when reading it. Export warns and writes
            % the second location as a copy under a new id instead.
            nwbFile = tests.factory.NWBFile();
            trials = tests.factory.TimeIntervals();
            nwbFile.intervals_trials = trials;
            nwbFile.intervals.set('custom_intervals_table_name', trials);

            filename = testCase.getRandomFilename();
            testCase.verifyWarning(...
                @() nwbExport(nwbFile, filename), ...
                'NWB:Export:DuplicateObjectId')

            % Both locations exist and hold distinct ids, so the file stays
            % readable by other NWB APIs.
            firstId = h5readatt(filename, '/intervals/trials', 'object_id');
            secondId = h5readatt(filename, ...
                '/intervals/custom_intervals_table_name', 'object_id');
            testCase.verifyNotEqual(firstId, secondId);
            testCase.verifyMatches(firstId, testCase.UuidPattern);
            testCase.verifyMatches(secondId, testCase.UuidPattern);
        end

        function testExportingDistinctObjectsToBothLocationsSucceeds(testCase)
            % The counterpart to testExportingOneObjectToTwoLocationsRaises:
            % two separate tables carry distinct ids and must export fine.
            nwbFile = tests.factory.NWBFile();
            nwbFile.intervals_trials = tests.factory.TimeIntervals();
            nwbFile.intervals.set(...
                'custom_intervals_table_name', tests.factory.TimeIntervals());

            filename = testCase.getRandomFilename();
            nwbExport(nwbFile, filename);
            testCase.verifyNotEqual(...
                h5readatt(filename, '/intervals/trials', 'object_id'), ...
                h5readatt(filename, '/intervals/custom_intervals_table_name', ...
                    'object_id'))
        end

        function testObjectWithUnresolvedReferenceExports(testCase)
            % Reference resolution re-exports an object at its original
            % location after its reference target has been written. That
            % second export of the same id must not be mistaken for the same
            % object being written to two locations.
            nwbFile = tests.factory.NWBFile();
            timeSeries = tests.factory.TimeSeries();
            nwbFile.acquisition.set('ts', timeSeries);
            % The link target is exported after the referring object
            nwbFile.scratch.set('reference', types.core.ScratchData(...
                'notes', 'reference to acquisition', ...
                'data', types.untyped.ObjectView(timeSeries)));

            filename = testCase.getRandomFilename();
            nwbExport(nwbFile, filename);
            testCase.verifyEqual(...
                h5readatt(filename, '/acquisition/ts', 'object_id'), ...
                timeSeries.object_id);
        end
    end
end
