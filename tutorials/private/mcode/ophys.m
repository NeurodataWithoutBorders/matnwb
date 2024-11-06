%% MatNWB Optical Physiology Tutorial
%% Introduction
% In this tutorial, we will create fake data for a hypothetical optical physiology 
% experiment with a freely moving animal. The types of data we will convert are:
%% 
% * Acquired two-photon images
% * Image segmentation (ROIs)
% * Fluorescence and dF/F response
%% 
% It is recommended to first work through the <https://neurodatawithoutborders.github.io/matnwb/tutorials/html/intro.html 
% Introduction to MatNWB tutorial>, which demonstrates installing MatNWB and creating 
% an NWB file with subject information, animal position, and trials, as well as 
% writing and reading NWB files in MATLAB.
%% Set up the NWB file
% An NWB file represents a single session of an experiment. Each file must have 
% a session_description, identifier, and session start time. Create a new |NWBFile| 
% object with those and additional metadata. For all MatNWB functions, we use 
% the Matlab method of entering keyword argument pairs, where arguments are entered 
% as name followed by value.

nwb = NwbFile( ...
    'session_description', 'mouse in open exploration',...
    'identifier', 'Mouse5_Day3', ...
    'session_start_time', datetime(2018, 4, 25, 2, 30, 3, 'TimeZone', 'local'), ...
    'timestamps_reference_time', datetime(2018, 4, 25, 3, 0, 45, 'TimeZone', 'local'), ...
    'general_experimenter', 'LastName, FirstName', ... % optional
    'general_session_id', 'session_1234', ... % optional
    'general_institution', 'University of My Institution', ... % optional
    'general_related_publications', {'DOI:10.1016/j.neuron.2016.12.011'}); % optional
nwb
%% Optical Physiology
% Optical physiology results are written in four steps:
%% 
% # Create imaging plane
% # Acquired two-photon images
% # Image segmentation
% # Fluorescence and dF/F responses
% Imaging Plane
% First, you must create an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ImagingPlane.html 
% |*ImagingPlane*|> object, which will hold information about the area and method 
% used to collect the optical imaging data. This requires creation of a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Device.html 
% |*Device*|> object for the microscope and an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/OpticalChannel.html 
% |*OpticalChannel*|> object. Then you can create an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ImagingPlane.html 
% |*ImagingPlane*|>.
% 
% 

optical_channel = types.core.OpticalChannel( ...
    'description', 'description', ...
    'emission_lambda', 500.);

device = types.core.Device();
nwb.general_devices.set('Device', device);

imaging_plane_name = 'imaging_plane';
imaging_plane = types.core.ImagingPlane( ...
    'optical_channel', optical_channel, ...
    'description', 'a very interesting part of the brain', ...
    'device', types.untyped.SoftLink(device), ...
    'excitation_lambda', 600., ...
    'imaging_rate', 5., ...
    'indicator', 'GFP', ...
    'location', 'my favorite brain location');

nwb.general_optophysiology.set(imaging_plane_name, imaging_plane);
% Storing Two-Photon Data
% You can create a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TwoPhotonSeries.html 
% |*TwoPhotonSeries*|> class representing two photon imaging data. <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TwoPhotonSeries.html 
% |*TwoPhotonSeries*|>, like <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/SpatialSeries.html 
% |*SpatialSeries*|>, inherits from <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeSeries.html 
% |*TimeSeries*|> and is similar in behavior to <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/OnePhotonSeries.html 
% |*OnePhotonSeries*|>|.|
% 
% 

InternalTwoPhoton = types.core.TwoPhotonSeries( ...
    'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
    'starting_time', 0.0, ...
    'starting_time_rate', 3.0, ...
    'data', ones(200, 100, 1000), ...
    'data_unit', 'lumens');

nwb.acquisition.set('2pInternal', InternalTwoPhoton);
% Storing One-Photon Data
% Now that we have our <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ImagingPlane.html 
% |*ImagingPlane*|>, we can create a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/OnePhotonSeries.html 
% |*OnePhotonSeries*|> object to store raw one-photon imaging data.

% using internal data. this data will be stored inside the NWB file
InternalOnePhoton = types.core.OnePhotonSeries( ...
    'data', ones(100, 100, 1000), ...
    'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
    'starting_time', 0., ...
    'starting_time_rate', 1.0, ...
    'data_unit', 'normalized amplitude' ...
);
nwb.acquisition.set('1pInternal', InternalOnePhoton);
% Plane Segmentation
% Image segmentation stores the detected regions of interest in the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TwoPhotonSeries.html 
% |*TwoPhotonSeries*|> data. <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ImageSegmentation.html 
% |*ImageSegmentation*|> allows you to have more than one segmentation by creating 
% more <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/PlaneSegmentation.html 
% |*PlaneSegmentation*|> objects.
% 
% 
% Regions of interest (ROIs)
% ROIs can be added to a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/PlaneSegmentation.html 
% |*PlaneSegmentation*|> either as an image_mask *or* as a pixel_mask. An image 
% mask is an array that is the same size as a single frame of the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TwoPhotonSeries.html 
% |*TwoPhotonSeries*|>, and indicates where a single region of interest is. This 
% image mask may be boolean or continuous between 0 and 1. A pixel_mask, on the 
% other hand, is a list of indices (i.e coordinates) and weights for the ROI. 
% The pixel_mask is represented as a compound data type using a <https://nwb-schema.readthedocs.io/en/latest/format_description.html#tables-and-ragged-arrays 
% ragged array> and below is an example demonstrating how to create either an 
% image_mask or a pixel_mask. Changing the dropdown selection will update the 
% PlaneSegmentation object accordingly.

selection = "Create Image Mask"; % "Create Image Mask" or "Create Pixel Mask"

% generate fake image_mask data
imaging_shape = [100, 100];
x = imaging_shape(1);
y = imaging_shape(2);

n_rois = 20;
image_mask = zeros(y, x, n_rois);
center = randi(90,2,n_rois);
for i = 1:n_rois
    image_mask(center(1,i):center(1,i)+10, center(2,i):center(2,i)+10, i) = 1;
end

if selection == "Create Pixel Mask"
    ind = find(image_mask);
    [y_ind, x_ind, roi_ind] = ind2sub(size(image_mask), ind);

    pixel_mask_struct = struct();
    pixel_mask_struct.x = uint32(x_ind); % Add x coordinates to struct field x
    pixel_mask_struct.y = uint32(y_ind); % Add y coordinates to struct field y
    pixel_mask_struct.weight = single(ones(size(x_ind))); 
    
    % Create pixel mask vector data
    pixel_mask = types.hdmf_common.VectorData(...
            'data', struct2table(pixel_mask_struct), ...
            'description', 'pixel masks');

    % When creating a pixel mask, it is also necessary to specify a
    % pixel_mask_index vector. See the documentation for ragged arrays linked
    % above to learn more.
    num_pixels_per_roi = zeros(n_rois, 1); % Column vector
    for i_roi = 1:n_rois
        num_pixels_per_roi(i_roi) = sum(roi_ind == i_roi);
    end

    pixel_mask_index = uint16(cumsum(num_pixels_per_roi)); % Note: Use an integer 
    % type that can accommodate the maximum value of the cumulative sum

    % Create pixel_mask_index vector
    pixel_mask_index = types.hdmf_common.VectorIndex(...
            'description', 'Index into pixel_mask VectorData', ...
            'data', pixel_mask_index, ...
            'target', types.untyped.ObjectView(pixel_mask) );

    plane_segmentation = types.core.PlaneSegmentation( ...
        'colnames', {'pixel_mask'}, ...
        'description', 'roi pixel position (x,y) and pixel weight', ...
        'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
        'pixel_mask_index', pixel_mask_index, ...
        'pixel_mask', pixel_mask ...
    );

else % selection == "Create Image Mask"
    plane_segmentation = types.core.PlaneSegmentation( ...
        'colnames', {'image_mask'}, ...
        'description', 'output from segmenting my favorite imaging plane', ...
        'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
        'image_mask', types.hdmf_common.VectorData(...
            'data', image_mask, ...
            'description', 'image masks') ...
    );
end
% Adding ROIs to NWB file 
% Now create an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ImageSegmentation.html 
% |*ImageSegmentation*|> object and put the |plane_segmentation| object inside 
% of it, naming it <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/PlaneSegmentation.html 
% |*PlaneSegmentation*|>.

img_seg = types.core.ImageSegmentation();
img_seg.planesegmentation.set('PlaneSegmentation', plane_segmentation);
%% 
% Now create a <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ProcessingModule.html 
% |*ProcessingModule*|> called "ophys" and put our |img_seg| object in it, calling 
% it "|ImageSegmentation"|, and add the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ProcessingModule.html 
% |*ProcessingModule*|> to |nwb.|

ophys_module = types.core.ProcessingModule( ...
    'description',  'contains optical physiology data')
ophys_module.nwbdatainterface.set('ImageSegmentation', img_seg);
nwb.processing.set('ophys', ophys_module);
% Storing fluorescence of ROIs over time
% Now that ROIs are stored, you can store fluorescence dF/F data for these regions 
% of interest. This type of data is stored using the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/RoiResponseSeries.html 
% |*RoiResponseSeries*|> class. You will not need to instantiate this class directly 
% to create objects of this type, but it is worth noting that this is the class 
% you will work with after you read data back in.
% 
% 
% 
% First, create a data interface to store this data in

roi_table_region = types.hdmf_common.DynamicTableRegion( ...
    'table', types.untyped.ObjectView(plane_segmentation), ...
    'description', 'all_rois', ...
    'data', (0:n_rois-1)');

roi_response_series = types.core.RoiResponseSeries( ...
    'rois', roi_table_region, ...
    'data', NaN(n_rois, 100), ...
    'data_unit', 'lumens', ...
    'starting_time_rate', 3.0, ...
    'starting_time', 0.0);

fluorescence = types.core.Fluorescence();
fluorescence.roiresponseseries.set('RoiResponseSeries', roi_response_series);

ophys_module.nwbdatainterface.set('Fluorescence', fluorescence);
%% 
% Finally, the ophys <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ProcessingModule.html 
% |*ProcessingModule*|> is added to the |NwbFile|.

nwb.processing.set('ophys', ophys_module);
%% Writing the NWB file

nwb_file_name = 'ophys_tutorial.nwb';
if isfile(nwb_file_name); delete(nwb_file_name); end
nwbExport(nwb, nwb_file_name);
%% Reading the NWB file

read_nwb = nwbRead(nwb_file_name, 'ignorecache');
%% 
% Data arrays are read passively from the file. Calling |TimeSeries.data| does 
% not read the data values, but presents an HDF5 object that can be indexed to 
% read data. 

read_nwb.processing.get('ophys').nwbdatainterface.get('Fluorescence')...
    .roiresponseseries.get('RoiResponseSeries').data
%% 
% This allows you to conveniently work with datasets that are too large to fit 
% in RAM all at once. Access the data in the matrix using the |load| method. 
% 
% |load| with no input arguments reads the entire dataset:

read_nwb.processing.get('ophys').nwbdatainterface.get('Fluorescence'). ...
    roiresponseseries.get('RoiResponseSeries').data.load
%% 
% If all you need is a section of the data, you can read only that section by 
% indexing the |DataStub| object like a normal array in MATLAB. This will just 
% read the selected region from disk into RAM. This technique is particularly 
% useful if you are dealing with a large dataset that is too big to fit entirely 
% into your available RAM.

read_nwb.processing.get('ophys'). ...
    nwbdatainterface.get('Fluorescence'). ...
    roiresponseseries.get('RoiResponseSeries'). ...
    data(1:5, 1:10)
% read back the image/pixel masks and display the first roi
plane_segmentation = read_nwb.processing.get('ophys'). ...
    nwbdatainterface.get('ImageSegmentation'). ...
    planesegmentation.get('PlaneSegmentation');

if ~isempty(plane_segmentation.image_mask)
    roi_mask = plane_segmentation.image_mask.data(:,:,1);
elseif ~isempty(plane_segmentation.pixel_mask)
    row = plane_segmentation.getRow(1, 'columns', {'pixel_mask'});
    pixel_mask = row.pixel_mask{1};
    roi_mask = zeros(imaging_shape);
    ind = sub2ind(imaging_shape, pixel_mask.y, pixel_mask.x);
    roi_mask(ind) = pixel_mask.weight;
end    
imshow(roi_mask)
%% Learn more!
% See the <https://neurodatawithoutborders.github.io/matnwb/doc/index.html API documentation> to learn what data types are available.
%% Other MatNWB tutorials
%% 
% * <https://neurodatawithoutborders.github.io/matnwb/tutorials/html/ecephys.html 
% Extracellular electrophysiology>
% * <https://neurodatawithoutborders.github.io/matnwb/tutorials/html/icephys.html 
% Intracellular electrophysiology>
%% Python tutorials
% See our tutorials for more details about your data type:
%% 
% * <https://pynwb.readthedocs.io/en/stable/tutorials/domain/ecephys.html#sphx-glr-tutorials-domain-ecephys-py 
% Extracellular electrophysiology>
% * <https://pynwb.readthedocs.io/en/stable/tutorials/domain/ophys.html#sphx-glr-tutorials-domain-ophys-py 
% Calcium imaging>
% * <https://pynwb.readthedocs.io/en/stable/tutorials/domain/icephys.html#sphx-glr-tutorials-domain-icephys-py 
% Intracellular electrophysiology>
%% 
% *Check out other tutorials that teach advanced NWB topics:*
%% 
% * <https://pynwb.readthedocs.io/en/stable/tutorials/general/iterative_write.html#sphx-glr-tutorials-general-iterative-write-py 
% Iterative data write>
% * <https://pynwb.readthedocs.io/en/stable/tutorials/general/extensions.html#sphx-glr-tutorials-general-extensions-py 
% Extensions>
% * <https://pynwb.readthedocs.io/en/stable/tutorials/general/advanced_hdf5_io.html#sphx-glr-tutorials-general-advanced-hdf5-io-py 
% Advanced HDF5 I/O>
%%