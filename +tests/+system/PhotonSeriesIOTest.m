classdef PhotonSeriesIOTest < tests.system.PyNWBIOTest & tests.system.AmendTest
    methods
        function addContainer(testCase, file) %#ok<INUSL>
            dev = types.core.Device('description', 'dev1 description');
            
            oc = types.core.OpticalChannel( ...
                'description', 'a fake OpticalChannel', ...
                'emission_lambda', 3.14);
            ip = types.core.ImagingPlane( ...
                'description', 'a fake ImagingPlane', ...
                'optchan1', oc, ...
                'device', types.untyped.SoftLink(dev), ...
                'excitation_lambda', 6.28, ...
                'imaging_rate', 2.718, ...
                'indicator', 'GFP', ...
                'location', 'somewhere in the brain');
            
            tps = types.core.TwoPhotonSeries( ...
                'data', ones(3,3,10), ...
                'imaging_plane', types.untyped.SoftLink(ip), ...
                'data_unit', 'image_unit', ...
                'format', 'raw', ...
                'field_of_view', [2, 2, 5] .', ...
                'pmt_gain', 1.7, ...
                'scan_line_rate', 3.4, ...
                'timestamps', (0:9) .', ...
                'dimension', [200;200]);
            
            file.general_devices.set('dev1', dev);
            file.general_optophysiology.set('imgpln1', ip);
            file.acquisition.set('test_2ps', tps);
        end
        
        function c = getContainer(testCase, file) %#ok<INUSL>
            c = file.acquisition.get('test_2ps');
        end
        
        function appendContainer(~, file)
            oldImagingPlane = file.general_optophysiology.get('imgpln1');
            newImagingPlane = types.core.ImagingPlane(...
                'description', 'a different imaging plane',...
                'device', oldImagingPlane.device,...
                'optchan1', oldImagingPlane.opticalchannel.get('optchan1'),...
                'excitation_lambda', 1,...
                'imaging_rate', 2,...
                'indicator', 'ASL',...
                'location', 'somewhere else in the brain');
            file.general_optophysiology.set('imgpln2', newImagingPlane);
            
            hTwoPhotonSeries = file.acquisition.get('test_2ps');
            hTwoPhotonSeries.imaging_plane = types.untyped.SoftLink(newImagingPlane);
            hTwoPhotonSeries.data = hTwoPhotonSeries.data + rand();
        end
    end
end

