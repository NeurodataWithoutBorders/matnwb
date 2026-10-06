classdef SharedEntryTest < tests.unit.abstract.SchemaTest
% SharedEntryTest - Tests for an object held by two unnamed groups.
%
% ImagingPlaneWithSubtypeChannels inherits the opticalchannel group
% (OpticalChannel) from ImagingPlane and adds the opticalchannelsubtype
% group (OpticalChannelSubtype, a subtype of OpticalChannel). An
% OpticalChannelSubtype entry matches both groups.

    properties (Constant)
        SchemaFolder = "sharedEntrySchema"
        SchemaNamespaceFileName = "ses.namespace.yaml"
    end

    methods (TestMethodSetup)
        function setupMethod(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testSubtypeEntryIsHeldByBothGroups(testCase)
            channel = testCase.createSubtypeChannel();
            plane = testCase.createPlane('GFP', channel);

            testCase.verifySameHandle(plane.opticalchannel.get('GFP'), channel)
            testCase.verifySameHandle(plane.opticalchannelsubtype.get('GFP'), channel)
            testCase.verifySameHandle(plane.GFP, channel)
        end

        function testDifferentObjectWithExistingNameErrors(testCase)
            plane = testCase.createPlane('Channel', testCase.createChannel());

            testCase.verifyError( ...
                @() plane.opticalchannelsubtype.set('Channel', testCase.createSubtypeChannel()), ...
                'NWB:HasUnnamedGroups:DuplicateEntry')
            testCase.verifyFalse(plane.opticalchannelsubtype.isKey('Channel'))
            testCase.verifyClass(plane.Channel, 'types.core.OpticalChannel')
        end

        function testRemoveDeletesSharedEntryFromAllGroups(testCase)
            plane = testCase.createPlane('GFP', testCase.createSubtypeChannel());

            plane.remove('GFP')

            testCase.verifyFalse(plane.opticalchannel.isKey('GFP'))
            testCase.verifyFalse(plane.opticalchannelsubtype.isKey('GFP'))
            testCase.verifyFalse(isprop(plane, 'GFP'))
        end

        function testPropertyRemainsWhileAnyGroupHoldsName(testCase)
            channel = testCase.createSubtypeChannel();
            plane = testCase.createPlane('GFP', channel);

            plane.opticalchannelsubtype.remove('GFP')

            testCase.verifySameHandle(plane.GFP, channel)
        end

        function testAssigningUpdatesEveryGroupThatAcceptsValue(testCase)
            plane = testCase.createPlane('GFP', testCase.createSubtypeChannel());

            newSubtypeChannel = testCase.createSubtypeChannel();
            plane.GFP = newSubtypeChannel;
            testCase.verifySameHandle(plane.opticalchannel.get('GFP'), newSubtypeChannel)
            testCase.verifySameHandle(plane.opticalchannelsubtype.get('GFP'), newSubtypeChannel)

            % A plain OpticalChannel does not fit the subtype group.
            newChannel = testCase.createChannel();
            plane.GFP = newChannel;
            testCase.verifySameHandle(plane.opticalchannel.get('GFP'), newChannel)
            testCase.verifyFalse(plane.opticalchannelsubtype.isKey('GFP'))
        end

        function testAssigningValueNoGroupAcceptsErrors(testCase)
            channel = testCase.createSubtypeChannel();
            plane = testCase.createPlane('GFP', channel);

            testCase.verifyError(@() setGFP(plane, types.core.Device()), ...
                'NWB:Set:FailedValidation')
            testCase.verifySameHandle(plane.opticalchannel.get('GFP'), channel)
            testCase.verifySameHandle(plane.opticalchannelsubtype.get('GFP'), channel)
        end

        function testRoundTripWritesSharedEntryOnce(testCase)
            device = types.core.Device();
            channel = testCase.createSubtypeChannel();
            plane = testCase.createPlane('GFP', channel, device);

            nwb = NwbFile( ...
                'identifier', 'SES', ...
                'session_description', 'shared entry schema testing', ...
                'session_start_time', datetime(2024, 1, 1, 'TimeZone', 'local'));
            nwb.general_devices.set('Microscope', device);
            nwb.general_optophysiology.set('Plane', plane);
            nwbExport(nwb, 'testses.nwb');

            planeInfo = h5info('testses.nwb', '/general/optophysiology/Plane');
            testCase.verifyEqual({planeInfo.Groups.Name}, ...
                {'/general/optophysiology/Plane/GFP'})

            nwbIn = nwbRead('testses.nwb', 'ignorecache');
            planeIn = nwbIn.general_optophysiology.get('Plane');
            testCase.verifyClass(planeIn.GFP, 'types.ses.OpticalChannelSubtype')
            testCase.verifySameHandle( ...
                planeIn.opticalchannel.get('GFP'), planeIn.opticalchannelsubtype.get('GFP'))
        end
    end

    methods (Static)
        function plane = createPlane(channelName, channel, device)
            if nargin < 3
                device = types.core.Device();
            end
            plane = types.ses.ImagingPlaneWithSubtypeChannels( ...
                'device', types.untyped.SoftLink(device), ...
                'excitation_lambda', 488, ...
                'indicator', 'GCaMP6f', ...
                'location', 'V1', ...
                channelName, channel);
        end

        function channel = createChannel()
            channel = types.core.OpticalChannel( ...
                'description', 'Green channel', ...
                'emission_lambda', 525);
        end

        function channel = createSubtypeChannel()
            channel = types.ses.OpticalChannelSubtype( ...
                'description', 'Green channel', ...
                'emission_lambda', 525);
        end
    end
end

function setGFP(plane, value)
    plane.GFP = value;
end
