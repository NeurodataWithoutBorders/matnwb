%% Storing Image Data in NWB
% Image data can be a collection of individual images or movie segments (as 
% a movie is simply a series of images), about the subject, the environment, the 
% presented stimuli, or other parts related to the experiment. This tutorial focuses 
% in particular on the usage of:
%% 
% * <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/OpticalSeries.html 
% |*types.core.OpticalSeries*|> and <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/AbstractFeatureSeries.html 
% |*types.core.AbstractFeatureSeries*|> for series of images that were presented 
% as stimulus
% * <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ImageSeries.html 
% |*types.core.ImageSeries*|>, for series of images (movie segments);
% * <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/GrayscaleImage.html 
% |*types.core.GrayscaleImage*|>, <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/RGBImage.html 
% |*types.core.RGBImage*|>, and <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/RGBAImage.html 
% |*types.core.RGBAImage*|>, for static images
%% Create an NWB File

nwb = NwbFile( ...
    'session_description', 'mouse in open exploration',...
    'identifier', 'Mouse5_Day3', ...
    'session_start_time', datetime(2018, 4, 25, 2, 30, 3, 'TimeZone', 'local'), ...
    'timestamps_reference_time', datetime(2018, 4, 25, 3, 0, 45, 'TimeZone', 'local'), ...
    'general_experimenter', 'LastName, FirstName', ... % optional
    'general_session_id', 'session_1234', ... % optional
    'general_institution', 'University of My Institution', ... % optional
    'general_related_publications', 'DOI:10.1016/j.neuron.2016.12.011' ... % optional
);
nwb
%% OpticalSeries: Storing series of images as stimuli
% <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/OpticalSeries.html 
% |*OpticalSeries*|> is for time series of images that were presented to the subject 
% as stimuli. We will create an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/OpticalSeries.html 
% |*OpticalSeries*|> object with the name |"StimulusPresentation"| representing 
% what images were shown to the subject and at what times.
% 
% Image data can be stored either in the HDF5 file or as an external image file. 
% For this tutorial, we will use fake image data with shape of |('time', 'x', 
% 'y', 'RGB') = (200, 50, 50, 3)|. As in all <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/TimeSeries.html 
% |*TimeSeries*|>, the first dimension is time. The second and third dimensions 
% represent x and y. The fourth dimension represents the RGB value (length of 
% 3) for color images. *Please note*: As described in the <https://neurodatawithoutborders.github.io/matnwb/tutorials/html/dimensionMapNoDataPipes.html 
% dimensionMapNoDataPipes> tutorial, when a MATLAB array is exported to HDF5, 
% the array is transposed. Therefore, in order to correctly export the data, we 
% will need to create a transposed array, where the dimensions are in reverse 
% order compared to the type specification.
% 
% NWB differentiates between acquired data and data that was presented as stimulus. 
% We can add it to the <https://neurodatawithoutborders.github.io/matnwb/doc/NwbFile.html 
% |*NWBFile*|> object as stimulus data.
% 
% If the sampling rate is constant, use |rate| and |starting_time| to specify 
% time. For irregularly sampled recordings, use |timestamps| to specify time for 
% each sample image.

image_data = randi(255, [3, 50, 50, 200]); % NB: Array is transposed
optical_series = types.core.OpticalSeries( ...
    'distance', 0.7, ...  % required
    'field_of_view', [0.2, 0.3, 0.7], ...  % required
    'orientation', 'lower left', ...  % required
    'data', image_data, ...
    'data_unit', 'n.a.', ...
    'starting_time_rate', 1.0, ...
    'starting_time', 0.0, ...
    'description', 'The images presented to the subject as stimuli' ...
);

nwb.stimulus_presentation.set('StimulusPresentation', optical_series);
%% AbstractFeatureSeries: Storing features of visual stimuli
% While it is usually recommended to store the entire image data as an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/OpticalSeries.html 
% |*OpticalSeries*|>, sometimes it is useful to store features of the visual stimuli 
% instead of or in addition to the raw image data. For example, you may want to 
% store the mean luminance of the image, the contrast, or the spatial frequency. 
% This can be done using an instance of <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/AbstractFeatureSeries.html 
% |*AbstractFeatureSeries*|>. This class is a general container for storing time 
% series of features that are derived from the raw image data.

% Create some fake feature data
feature_data = rand(3, 200);  % 200 time points, 3 features

% Create an AbstractFeatureSeries object
abstract_feature_series = types.core.AbstractFeatureSeries( ...
    'data', feature_data, ...
    'timestamps', linspace(0, 1, 200), ...
    'description', 'Features of the visual stimuli', ...
    'features', {'luminance', 'contrast', 'spatial frequency'}, ...
    'feature_units', {'n.a.', 'n.a.', 'cycles/degree'} ...
);
% Add the AbstractFeatureSeries to the NWBFile
nwb.stimulus_presentation.set('StimulusFeatures', abstract_feature_series);
%% ImageSeries: Storing series of images as acquisition
% <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ImageSeries.html 
% |*ImageSeries*|> is a general container for time series of images acquired during 
% the experiment. Image data can be stored either in the HDF5 file or as an external 
% image file. When color images are stored in the HDF5 file the color channel 
% order is expected to be RGB.

image_data = randi(255, [3, 50, 50, 200]);
behavior_images = types.core.ImageSeries( ...
    'data', image_data, ...
    'description', 'Image data of an animal in environment', ...
    'data_unit', 'n.a.', ...
    'starting_time_rate', 1.0, ...
    'starting_time', 0.0 ...
);

nwb.acquisition.set('ImageSeries', behavior_images);
%% External Files
% External files (e.g. video files of the behaving animal) can be added to the 
% <https://neurodatawithoutborders.github.io/matnwb/doc/NwbFile.html |*NWBFile*|> 
% by creating an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ImageSeries.html 
% |*ImageSeries*|> object using the |external_file| attribute that specifies the 
% path to the external file(s) on disk. The file(s) path must be relative to the 
% path of the NWB file. Either |external_file| or |data| must be specified, but 
% not both. |external_file| can be a cell array of multiple video files.
% 
% The |starting_frame| attribute serves as an index to indicate the starting 
% frame of each external file, allowing you to skip the beginning of videos.

external_files = {'video1.pmp4', 'video2.pmp4'};

timestamps = [0.0, 0.04, 0.07, 0.1, 0.14, 0.16, 0.21];
behavior_external_file = types.core.ImageSeries( ...
    'description', 'Behavior video of animal moving in environment', ...
    'data_unit', 'n.a.', ...
    'external_file', external_files, ...
    'format', 'external', ...
    'external_file_starting_frame', [0, 2], ...
    'timestamps', timestamps ...
);

nwb.acquisition.set('ExternalVideos', behavior_external_file);
%% Static Images
% Static images can be stored in an <https://neurodatawithoutborders.github.io/matnwb/doc/NwbFile.html 
% |*NWBFile*|> object by creating an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/RGBAImage.html 
% |*RGBAImage*|>, <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/RGBImage.html 
% |*RGBImage*|> or <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/GrayscaleImage.html 
% |*GrayscaleImage*|> object with the image data. All of these image types provide 
% an optional |description| parameter to include text description about the image 
% and the |resolution| parameter to specify the pixels/cm resolution of the image.
% RGBAImage: for color images with transparency
% <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/RGBAImage.html 
% |*RGBAImage*|> is for storing data of color image with transparency. |data| 
% must be 3D where the first and second dimensions represent x and y. The third 
% dimension has length 4 and represents the RGBA value.

image_data = randi(255, [4, 200, 200]);

rgba_image = types.core.RGBAImage( ...
    'data', image_data, ...  % required
    'resolution', 70.0, ...
    'description', 'RGBA image' ...
);
% RGBImage: for color images
% <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/RGBImage.html 
% |*RGBImage*|> is for storing data of RGB color image. |data| must be 3D where 
% the first and second dimensions represent x and y. The third dimension has length 
% 3 and represents the RGB value.

image_data = randi(255, [3, 200, 200]);

rgb_image = types.core.RGBImage( ...
    'data', image_data, ...  % required
    'resolution', 70.0, ...
    'description', 'RGB image' ...
);
% *GrayscaleImage: for grayscale images*
% <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/GrayscaleImage.html 
% |*GrayscaleImage*|> is for storing grayscale image data. |data| must be 2D where 
% the first and second dimensions represent x and y.

image_data = randi(255, [200, 200]);

grayscale_image = types.core.GrayscaleImage( ...
    'data', image_data, ...  % required
    'resolution', 70.0, ...
    'description', 'Grayscale image' ...
);
% Images: a container for images
% Add the images to an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Images.html 
% |*Images*|> container that accepts any of these image types.

image_collection = types.core.Images( ...
    'description', 'A collection of logo images presented to the subject.'...
);

image_collection.image.set('rgba_image', rgba_image);
image_collection.image.set('rgb_image', rgb_image);
image_collection.image.set('grayscale_image', grayscale_image);

nwb.acquisition.set('image_collection', image_collection);
%% Index Series for Repeated Images
% You may want to set up a time series of images where some images are repeated 
% many times. You could create an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ImageSeries.html 
% |ImageSeries|> that repeats the data each time the image is shown, but that 
% would be inefficient, because it would store the same data multiple times. A 
% better solution would be to store the unique images once and reference those 
% images. This is how <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/IndexSeries.html 
% |IndexSeries|> works. First, create an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Images.html 
% |Images|> container with the order of images defined using an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/ImageReferences.html 
% |ImageReferences|>. Then create an <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/IndexSeries.html 
% |IndexSeries|> that indexes into the <https://neurodatawithoutborders.github.io/matnwb/doc/+types/+core/Images.html 
% |Images|>.

rgbImage = imread('street2.jpg');
grayImage = uint8(sum(double(rgbImage), 3) ./ double(max(max(max(rgbImage)))));
GsStreet = types.core.GrayscaleImage(...
    'data', grayImage, ...
    'description', 'grayscale image of a street.', ...
    'resolution', 28 ...
);

RgbStreet = types.core.RGBImage( ...
    'data', rgbImage, ...
    'resolution', 28, ...
    'description', 'RGB Street' ...
);

ImageOrder = types.core.ImageReferences(...
    'data', [types.untyped.ObjectView(RgbStreet), types.untyped.ObjectView(GsStreet)] ...
);
Images = types.core.Images( ...
    'gs_face', GsStreet, ...
    'rgb_face', RgbStreet, ...
    'description', 'A collection of streets.', ...
    'order_of_images', ImageOrder ...
);

types.core.IndexSeries(...
    'data', [0, 1, 0, 1], ... % NOTE: 0-indexed
    'indexed_images', Images, ...
    'timestamps', [0.1, 0.2, 0.3, 0.4] ...
)
%% 
% Here _data_ contains the (0-indexed) index of the displayed image as they 
% are ordered in the |ImageReference|.
%% Writing the images to an NWB File
% Now use <https://neurodatawithoutborders.github.io/matnwb/doc/nwbExport.html 
% |*nwbExport*|> to write the file.

nwbExport(nwb, "images_test.nwb");