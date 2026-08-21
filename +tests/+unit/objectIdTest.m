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
            timeSeriesA = testCase.createTimeSeries();
            timeSeriesB = testCase.createTimeSeries();

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
            timeSeries = testCase.createTimeSeries();
            testCase.verifyError(...
                @() setfield(timeSeries, 'object_id', 'other'), ...
                'MATLAB:class:SetProhibited');
        end

        function testObjectIdStableAcrossExports(testCase)
            nwbFile = tests.factory.NWBFile();
            timeSeries = testCase.createTimeSeries();
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
            nwbFile.acquisition.set('ts', testCase.createTimeSeries());

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
            nwbFile.intervals_trials = testCase.createTrialsTable();

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
            nwbFile.acquisition.set('ts', testCase.createTimeSeries());

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
            trials = testCase.createTrialsTable();
            tableId = trials.object_id;
            columnId = trials.start_time.object_id;

            trials.generateNewObjectId('Recurse', false);
            testCase.verifyNotEqual(trials.object_id, tableId);
            testCase.verifyMatches(trials.object_id, testCase.UuidPattern);
            testCase.verifyEqual(trials.start_time.object_id, columnId);
        end

        function testGenerateNewObjectIdRecursesIntoContainedTypes(testCase)
            nwbFile = tests.factory.NWBFile();
            nwbFile.intervals_trials = testCase.createTrialsTable();
            timeSeries = testCase.createTimeSeries();
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
    end

    methods (Static, Access = private)
        function timeSeries = createTimeSeries()
            timeSeries = types.core.TimeSeries(...
                'data', (1:10)', ...
                'data_unit', 'a.u.', ...
                'starting_time', 0, ...
                'starting_time_rate', 1);
        end

        function trials = createTrialsTable()
            trials = types.core.TimeIntervals(...
                'description', 'trials', ...
                'colnames', {'start_time', 'stop_time'}, ...
                'id', types.hdmf_common.ElementIdentifiers('data', int64([0; 1])), ...
                'start_time', types.hdmf_common.VectorData(...
                    'description', 'start', 'data', [0; 1]), ...
                'stop_time', types.hdmf_common.VectorData(...
                    'description', 'stop', 'data', [1; 2]));
        end
    end
end
