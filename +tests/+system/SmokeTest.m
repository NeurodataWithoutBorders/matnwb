classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
    SmokeTest < matlab.unittest.TestCase
% Test construction of all core (including hdmf_common) types
% Test simple read write for HDF5-based nwb file

    properties (Constant)
        NAMESPACES = ["core", "hdmf_common"]
    end

    properties (TestParameter)
        % typeName - Fully qualified name of a generated core/hdmf_common
        % type, keyed by a readable identifier for use in test names.
        typeName = listCoreTypeNames();
    end

    methods (TestClassSetup)
        function setup(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            testCase.applyFixture(SuppressedWarningsFixture('NWB:AttributeDependencyNotSet'))
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testSmokeInstantiateCore(testCase, typeName) %#ok<INUSD>
            % Construct a generated type with no arguments to confirm the
            % class definition is at least syntactically valid and loadable.
            feval(str2func(typeName));
        end

        function testSmokeReadWrite(testCase)
            % Create a TimeIntervals object
            epochs = types.core.TimeIntervals( ...
                'colnames', {'start_time'; 'stop_time'} , ...
                'id', types.hdmf_common.ElementIdentifiers('data', 1), ...
                'description', 'test TimeIntervals', ...
                'start_time', types.hdmf_common.VectorData('data', 0, 'description', 'start time'), ...
                'stop_time', types.hdmf_common.VectorData('data', 1, 'description', 'stop time'));

            % Create an NwbFile and export
            file = NwbFile( ...
                'identifier', 'st', ...
                'session_description', 'smokeTest', ...
                'session_start_time', datetime, ...
                'intervals_epochs', epochs, ...
                'timestamps_reference_time', datetime);
            nwbExport(file, 'epoch.nwb');

            % Read the file back
            readFile = nwbRead('epoch.nwb', 'ignorecache');

            tests.util.verifyContainerEqual(testCase, readFile, file);
        end

        function testReservedKeywordPropertyRoundTrip(testCase)
            % The NWBFile "events" field is a reserved MATLAB keyword, so it is
            % exposed as the property "events_" and stored on disk as "/events".
            % Verify the property name, the on-disk name, and a full round-trip.
            testCase.verifyTrue(isprop(types.core.NWBFile(), 'events_'), ...
                'Reserved schema field "events" should map to property "events_"')

            eventsTable = types.core.EventsTable( ...
                'description', 'detected events', ...
                'colnames', {'timestamp'}, ...
                'id', types.hdmf_common.ElementIdentifiers('data', int64([0;1;2])), ...
                'timestamp', types.core.TimestampVectorData( ...
                    'data', [0.1; 0.5; 1.2], 'description', 'event times'));

            eventsSet = types.untyped.Set();
            eventsSet.set('detected', eventsTable);

            file = NwbFile( ...
                'identifier', 'evt', ...
                'session_description', 'reserved keyword test', ...
                'session_start_time', datetime, ...
                'timestamps_reference_time', datetime, ...
                'events_', eventsSet);
            nwbExport(file, 'events.nwb');

            % The schema name is preserved on disk, not the MATLAB identifier.
            diskGroup = h5info('events.nwb', '/events');
            testCase.verifyEqual({diskGroup.Groups.Name}, {'/events/detected'})

            readFile = nwbRead('events.nwb', 'ignorecache');
            tests.util.verifyContainerEqual(testCase, readFile, file);

            % searchFor and resolve must use the schema name in paths, not the
            % property identifier, and must be consistent with each other.
            foundPaths = readFile.searchFor('types.core.EventsTable').keys();
            testCase.verifyEqual(foundPaths, {'/events/detected'})
            testCase.verifyClass(readFile.resolve('/events/detected'), ...
                'types.core.EventsTable')
        end
    end
end

function typeNames = listCoreTypeNames()
% listCoreTypeNames - Fully qualified names of generated core/hdmf_common
% types, keyed by a readable identifier for use in parameterized test names.
    namespaceNames = tests.system.SmokeTest.NAMESPACES;
    typeNames = struct();
    for iNamespace = 1:numel(namespaceNames)
        namespaceName = namespaceNames{iNamespace};
        classFiles = dir(fullfile(misc.getMatnwbDir, '+types', ['+' namespaceName], '*.m'));
        for iClass = 1:numel(classFiles)
            [~, className] = fileparts(classFiles(iClass).name);
            if strcmp(className, 'Version')
                continue
            end
            key = [namespaceName '_' className];
            typeNames.(key) = sprintf('types.%s.%s', namespaceName, className);
        end
    end
end
