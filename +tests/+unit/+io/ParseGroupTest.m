classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
        ParseGroupTest < matlab.unittest.TestCase
% ParseGroupTest - Unit tests for io.parseGroup.
%
% The groups are described with io.backend.model objects and served by an
% in-memory reader, so these tests show that parsing depends on the reader
% interface and the node model only, not on a storage format.

    methods (Test)
        function testParseTypedGroupWithDatasets(testCase)
            import io.backend.model.AttributeInfo
            import io.backend.model.DatasetInfo
            import io.backend.model.GroupInfo

            data = DatasetInfo('data', AttributeInfo('unit', 'volts'));
            startingTime = DatasetInfo('starting_time', ...
                [AttributeInfo('rate', 10); AttributeInfo('unit', 'seconds')]);
            seriesInfo = GroupInfo('/acquisition/series', ...
                Datasets=[data; startingTime], ...
                Attributes=[ ...
                    AttributeInfo('neurodata_type', 'TimeSeries'); ...
                    AttributeInfo('namespace', 'core'); ...
                    AttributeInfo('description', 'a series')]);
            rootInfo = GroupInfo('/', ...
                Groups=GroupInfo('/acquisition', Groups=seriesInfo));

            datasetValues = containers.Map( ...
                {'/acquisition/series/data', '/acquisition/series/starting_time'}, ...
                {[1; 2; 3], 0.5});
            reader = tests.unit.io.backend.doubles.ReaderFake(rootInfo, datasetValues);

            series = io.parseGroup("in-memory", seriesInfo, ...
                io.internal.defaultParseExclusions(), reader);

            testCase.verifyClass(series, 'types.core.TimeSeries');
            testCase.verifyEqual(series.description, 'a series');
            testCase.verifyEqual(series.data, [1; 2; 3]);
            testCase.verifyEqual(series.data_unit, 'volts');
            testCase.verifyEqual(series.starting_time, 0.5);
            testCase.verifyEqual(series.starting_time_rate, 10);
        end

        function testParseGroupWithLinks(testCase)
            import io.backend.model.AttributeInfo
            import io.backend.model.GroupInfo
            import io.backend.model.LinkInfo

            deviceInfo = GroupInfo('/general/devices/probe', Attributes=[ ...
                AttributeInfo('neurodata_type', 'Device'); ...
                AttributeInfo('namespace', 'core')]);
            electrodeGroupInfo = GroupInfo('/general/extracellular_ephys/shank', ...
                Links=LinkInfo('device', 'soft link', '/general/devices/probe'), ...
                Attributes=[ ...
                    AttributeInfo('neurodata_type', 'ElectrodeGroup'); ...
                    AttributeInfo('namespace', 'core'); ...
                    AttributeInfo('description', 'a shank'); ...
                    AttributeInfo('location', 'CA1')]);
            rootInfo = GroupInfo('/', Groups=GroupInfo('/general', Groups=[ ...
                GroupInfo('/general/devices', Groups=deviceInfo); ...
                GroupInfo('/general/extracellular_ephys', Groups=electrodeGroupInfo)]));
            reader = tests.unit.io.backend.doubles.ReaderFake( ...
                rootInfo, containers.Map());

            warningCleanup = types.untyped.SoftLink.disablePathDeprecationWarning(); %#ok<NASGU>
            electrodeGroup = io.parseGroup("in-memory", electrodeGroupInfo, ...
                io.internal.defaultParseExclusions(), reader);

            testCase.verifyClass(electrodeGroup, 'types.core.ElectrodeGroup');
            testCase.verifyEqual(electrodeGroup.location, 'CA1');
            testCase.verifyClass(electrodeGroup.device, 'types.untyped.SoftLink');
            testCase.verifyEqual(electrodeGroup.device.path, '/general/devices/probe');
            testCase.verifyEqual(electrodeGroup.device.target_type, 'types.core.Device');
        end

        function testParseUntypedGroupWithExternalLink(testCase)
            import io.backend.model.GroupInfo
            import io.backend.model.LinkInfo

            groupInfo = GroupInfo('/analysis/linked', Links=LinkInfo( ...
                'remote', 'external link', '/acquisition/data', 'other.nwb'));
            reader = tests.unit.io.backend.doubles.ReaderFake( ...
                GroupInfo('/', Groups=groupInfo), containers.Map());

            parsed = io.parseGroup("in-memory", groupInfo, ...
                io.internal.defaultParseExclusions(), reader);

            link = parsed.get('remote');
            testCase.verifyClass(link, 'types.untyped.ExternalLink');
            testCase.verifyEqual(link.filename, 'other.nwb');
            testCase.verifyEqual(link.path, '/acquisition/data');
            testCase.verifyEqual(link.BasePath, '/in-memory');
        end

        function testRejectUnsupportedLinkType(testCase)
            import io.backend.model.GroupInfo
            import io.backend.model.LinkInfo

            groupInfo = GroupInfo('/analysis/linked', ...
                Links=LinkInfo('custom', 'user-defined link'));
            reader = tests.unit.io.backend.doubles.ReaderFake( ...
                GroupInfo('/', Groups=groupInfo), containers.Map());

            testCase.verifyError( ...
                @() io.parseGroup("in-memory", groupInfo, ...
                    io.internal.defaultParseExclusions(), reader), ...
                'NWB:ParseGroup:UnsupportedLinkType');
        end
    end
end
