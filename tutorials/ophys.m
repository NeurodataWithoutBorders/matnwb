%% Neurodata Without Borders: Neurophysiology (NWB:N), Calcium Imaging Tutorial
% How to write ophys data to an NWB file using matnwb.
% 
%  author: Ben Dichter
%  contact: ben.dichter@gmail.com
%  last edited: April 16, 2019

%% NWB file
% All contents get added to the NWB file, which is created with the
% following command

date = datetime(2018, 3, 1, 12, 0, 0);
session_start_time = datetime(date, ...
    'Format', 'yyyy-MM-dd''T''HH:mm:ssZZ', ...
    'TimeZone', 'local');

nwb = nwbfile( ...
    'session_description', 'a test NWB File', ...
    'identifier', 'mouse004_day4', ...
    'session_start_time', session_start_time);

%%
% You can check the contents by displaying the nwbfile object
disp(nwb);

%% Subject
% Subject-specific information goes in type |Subject| in location 
% |general_subject|.

nwb.general_subject = types.core.Subject( ...
    'description', 'mouse 5', 'age', '9 months', ...
    'sex', 'M', 'species', 'Mus musculus');

%% Imaging Plane

optical_channel = types.core.OpticalChannel( ...
    'description', 'description', ...
    'emission_lambda', 500.);

device_name = 'my_device';
nwb.general_devices.set(device_name, types.core.Device());

imaging_plane_name = 'imaging_plane';
imaging_plane = types.core.ImagingPlane( ...
    'optical_channel', optical_channel, ...
    'description', 'a very interesting part of the brain', ...
    'device', types.untyped.SoftLink(['/general/devices/' device_name]), ...
    'excitation_lambda', 600., ...
    'imaging_rate', 5., ...
    'indicator', 'GFP', ...
    'location', 'my favorite brain location', ...
    'manifold', ones(3, 5, 5), ...
    'manifold_conversion', 4, ...
    'manifold_unit', 'm', ...
    'reference_frame', 'A frame to refer to');

nwb.general_optophysiology.set(imaging_plane_name, imaging_plane);

imaging_plane_path = ['/general/optophysiology/' imaging_plane_name];

%% Two Photon Series
% You may store the image series data in the HDF5 file
image_series_name = 'image_series1';

image_series = types.core.TwoPhotonSeries( ...
    'imaging_plane', types.untyped.SoftLink(imaging_plane_path), ...
    'starting_time_rate', 3.0, ...
    'data', ones(200, 100, 1000), ...
    'data_unit', 'lumens');

nwb.acquisition.set(image_series_name, image_series);

%%
% You may link to a tiff file externally
image_series_name = 'image_series2';

image_series = types.core.TwoPhotonSeries( ...
    'external_file', 'images.tiff', ...
    'imaging_plane', types.untyped.SoftLink(imaging_plane_path), ...
    'external_file_starting_frame', 0, ...
    'format', 'tiff', ...
    'starting_time_rate', 3.0, ...
    'data', NaN, ...
    'data_unit', 'na');

nwb.acquisition.set(image_series_name, image_series);

%% Ophys Processing Module

ophys_module = types.core.ProcessingModule(...
    'description', 'holds processed calcium imaging data');

%% Plane Segmentation

% generate fake image_mask data
imaging_shape = [100, 200];
x = imaging_shape(1);
y = imaging_shape(2);

n_rois = 20;
image_mask = NaN(y, x, n_rois);
for i = 1:n_rois
    center = rand(1,2) .* [x,y];
    sigma = eye(2)*2;
    [X1,X2] = meshgrid(1:x,1:y);
    X = [X1(:) X2(:)];
    p = mvnpdf(X,center,sigma);
    Z = reshape(p,y,x);
    image_mask(:,:,i) = Z;
end

% add data to NWB structures
plane_segmentation = types.core.PlaneSegmentation( ...
    'colnames', {'imaging_mask', 'pixel_mask'}, ...
    'description', 'output from segmenting my favorite imaging plane', ...
    'id', types.core.ElementIdentifiers('data', int64(0:2)), ...
    'imaging_plane', imaging_plane);

plane_segmentation.image_mask = types.core.VectorData( ...
    'data', image_mask, 'description', 'image masks');

img_seg = types.core.ImageSegmentation();
img_seg.planesegmentation.set('plane_segmentation', plane_segmentation)

ophys_module.nwbdatainterface.set('image_segmentation', img_seg);
nwb.processing.set('ophys', ophys_module);


%% Fluoresence

plane_seg_object_view = types.untyped.ObjectView( ...
    '/processing/ophys/image_segmentation/plane_segmentation');

roi_table_region = types.core.DynamicTableRegion( ...
    'table', plane_seg_object_view, ...
    'description', 'all_rois', ...
    'data', [0 n_rois-1]');

roi_response_series = types.core.RoiResponseSeries( ...
    'rois', roi_table_region, ...
    'data', NaN(n_rois, 100), ...
    'data_unit', 'lumens', ...
    'starting_time_rate', 3.0);

fluorescence = types.core.Fluorescence();
fluorescence.roiresponseseries.set('roi_response_series', roi_response_series);

ophys_module.nwbdatainterface.set('fluorescence', fluorescence);
nwb.processing.set('ophys', ophys_module);


%% Write

nwbExport(nwb, 'ophys_tutorial.nwb');

%% Read

nwb = nwbRead('ophys_tutorial.nwb');

nwb.general_optophysiology.get('imaging_plane')

%nwb.acquisition.get('image_series1').data.load

