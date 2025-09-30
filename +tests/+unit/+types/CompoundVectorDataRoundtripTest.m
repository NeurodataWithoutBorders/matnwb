classdef CompoundVectorDataRoundtripTest < tests.abstract.NwbTestCase
% Test that VectorData with compound dtype is still a VectorData type after
% export/import

    methods (TestClassSetup)
        function setupTemporaryWorkingFolder(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testCompoundVectorDataRoundtrip(testCase)
            nwb = tests.factory.NWBFile;

            device = types.core.Device('description', 'test_device');
            nwb.general_devices.set('Device', device);

            imagingPlane = types.core.ImagingPlane(...
                'device', device , ...
                'excitation_lambda', 0, ...
                'indicator', 'N/A', ...
                'location', 'N/A');
            nwb.general_optophysiology.set('ImagingPlane', imagingPlane);

            pixelMasks = types.hdmf_common.VectorData(...
                'description', 'test pixel mask', ...
                'data', struct('x', 1:100, 'y', 1:100, 'weight', ones(1,100)));
            pixelMaskIndex = types.hdmf_common.VectorIndex(...
                'description', 'test pixel mask index', ...
                'data', 1:100, ...
                'target', types.untyped.ObjectView(pixelMasks));

            planeSegmentation = types.core.PlaneSegmentation(...
                'imaging_plane', imagingPlane, ...
                'description', 'test', ...
                'colnames', {'pixel_mask'}, ...
                'pixel_mask', pixelMasks, ...
                'pixel_mask_index', pixelMaskIndex);
            
            imageSegmentation = types.core.ImageSegmentation();
            imageSegmentation.planesegmentation.set('PlaneSegmentation', planeSegmentation);
            
            ophysModule = types.core.ProcessingModule( ...
                'description', 'Contains optical physiology data');
            ophysModule.nwbdatainterface.set('ImageSegmentation', imageSegmentation);
            nwb.processing.set('ophys', ophysModule);

            nwbExport(nwb, 'test.nwb')

            nwbIn = nwbRead('test.nwb', 'ignorecache');

            planeSegmentationIn = nwbIn.processing.get('ophys').nwbdatainterface.get('ImageSegmentation').planesegmentation.get('PlaneSegmentation');
            
            testCase.verifyClass(planeSegmentationIn.pixel_mask, 'types.hdmf_common.VectorData')
        end
    end
end
