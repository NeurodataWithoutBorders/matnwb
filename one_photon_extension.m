%% Code generation
%  Only have to do this once
%  Code gets put in the +types package in the current directory
%
% generateCore('schema/core/nwb.namespace.yaml');
% generateExtension('schema/mylab/mylab.namespace.yaml')

%% Now we build the dataset
% Reference python code:
%
% OnePhotonSeries = get_class('OnePhotonSeries', 'mylab')
% visual_stimulus_images = OnePhotonSeries(
%     name='stimulus',
%     source='NA',
%     data=np.random.rand(5,5,5),
%     unit='NA',
%     format='raw',
%     bins=5,
%     timestamps=[0.0])

ops=types.mylab.OnePhotonSeries(...
    'bins',int64(5),...
    'data',rand(5,5,5),...
    'source','NA',...
    'unit','NA');

nwb=types.core.NWBFile();
nwb.acquisition.set('stimulus', ops);
% nwbExport(nwb,'myfile.nwb');