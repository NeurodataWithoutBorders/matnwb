%% Storing Image Data in NWB
% In NWB, image data may be stored as collections of single images or as movie 
% segments and can describe the subject, the environment, presented stimuli, or 
% other experiment components. In this tutorial you will:
%% 
% * Use <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ImageSeries.html 
% |*types.core.ImageSeries*|> to store acquired image series (movie segments).
% * Use <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/OpticalSeries.html 
% |*types.core.OpticalSeries*|> and <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/AbstractFeatureSeries.html 
% |*types.core.AbstractFeatureSeries*| t>o store series of images or image features 
% that were presented as stimulus.
% * Use <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/GrayscaleImage.html 
% |*types.core.GrayscaleImage*|>, <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/RGBImage.html 
% |*types.core.RGBImage*|> and <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/RGBAImage.html 
% |*types.core.RGBAImage*|> to store static images.
%% 
% *Preliminary note:* As described in the <./dimensionMapNoDataPipes.mlx dimensionMapNoDataPipes> 
% tutorial, when a MATLAB array is exported to HDF5, the dimensions of the array 
% are reversed. Therefore, in order to correctly export the data, we will need 
% to reverse the order of dimensions in image and timeseries data before adding 
% these to NWB objects. The function below will be used for this purpose throughout 
% the tutorial:

% Anonymous function for reversing data dimensions for NWB compliance
reverseDims = @(data) permute(data, fliplr(1:ndims(data)));
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
%% ImageSeries: Storing series of images as acquisition
% <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ImageSeries.html 
% |*ImageSeries*|> is a general container for time series of images acquired during 
% an experiment. Image data can be stored directly in the NWB file or referenced 
% from external image files (see section External files below). For color images 
% stored in the NWB file, the channel order must be RGB. 

image_data = randi(255, [200, 50, 50, 3], 'uint8');
behavior_images = types.core.ImageSeries( ...
    'data', reverseDims(image_data), ...
    'description', 'Image data of an animal in the environment', ...
    'data_unit', 'n.a.', ...
    'starting_time_rate', 1.0, ...
    'starting_time', 0.0 ...
);

nwb.acquisition.set('ImageSeries', behavior_images);
%% OpticalSeries: Storing series of images as stimuli
% We will use the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/OpticalSeries.html 
% |*OpticalSeries*|> class to store time series of images presented to the subject 
% as stimuli. The <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/OpticalSeries.html 
% |*OpticalSeries*|> class extends the ImageSeries with additional fields that 
% describe the spatial relationship between the subject and the stimuli, such 
% as: 
%% 
% * |*field_of_view*| – physical extent of the image in the visual field or 
% target area.
% * |*distance*| – distance from the image source to the subject.
%% 
% Here we create an <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/OpticalSeries.html 
% |*OpticalSeries*|> named |StimulusPresentation| containing synthetic RGB image 
% data (As in all <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeSeries.html 
% |*TimeSeries*|>, the first dimension is time. The second and third dimensions 
% represent x and y and the fourth dimension represents the RGB value (length 
% of 3) for color images):

image_data = randi(255, [200, 50, 50, 3], 'uint8'); % time, x, y, RGB
optical_series = types.core.OpticalSeries( ...
    'distance', 0.7, ...  % recommended
    'field_of_view', [0.2, 0.3, 0.7], ...  % recommended
    'data', reverseDims(image_data), ...
    'data_unit', 'n.a.', ...
    'starting_time_rate', 1.0, ...
    'starting_time', 0.0, ...
    'description', 'The images presented to the subject as stimuli' ...
);

nwb.stimulus_presentation.set('StimulusPresentation', optical_series);
%% AbstractFeatureSeries: Storing features of visual stimuli
% While full image data is usually stored in an <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/OpticalSeries.html 
% |*OpticalSeries*|>, you can also store derived features of the visual stimuli—either 
% instead of, or in addition to, the raw images. Examples of derived features 
% include *mean luminance*, *contrast*, or *spatial frequency*. The <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/AbstractFeatureSeries.html 
% |*AbstractFeatureSeries*|> class is a general |TimeSeries| container for storing 
% such feature data over time.

% Create some fake feature data
feature_data = rand(200, 3);  % 200 time points, 3 features

% Create an AbstractFeatureSeries object
abstract_feature_series = types.core.AbstractFeatureSeries( ...
    'data', reverseDims(feature_data), ...
    'timestamps', linspace(0, 1, 200), ...
    'description', 'Features of the visual stimuli', ...
    'features', {'luminance', 'contrast', 'spatial frequency'}, ...
    'feature_units', {'n.a.', 'n.a.', 'cycles/degree'} ...
);

% Add the AbstractFeatureSeries to the NWBFile
nwb.stimulus_presentation.set('StimulusFeatures', abstract_feature_series);
%% External files
% External files (e.g., videos of the behaving animal) can be added to an <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/NWBFile.html 
% |*NWBFile*|> by creating an <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ImageSeries.html 
% |*ImageSeries*|> with the |external_file| field set to the relative path(s) 
% of the file(s) on disk. The path must be relative to the NWB file’s location.
% 
% Either |external_file| *or* |data| must be specified — not both. |external_file| 
% can be a cell array of multiple video files. 
% 
% The |starting_frame| attribute is a zero-based index into the full |ImageSeries| 
% that indicates the first frame contained in each file listed in |external_file|. 
% For example, if three files contain 5, 10, and 20 frames respectively, |starting_frame|would 
% be |[0, 5, 15]|. If one file contains all frames, it is |[0]|. This indexing 
% allows random access to frames without loading all preceding files.

external_files = {'video1.pmp4', 'video2.pmp4'};

timestamps = [0.0, 0.04, 0.07, 0.1, 0.14, 0.16, 0.21];
behavior_external_file = types.core.ImageSeries( ...
    'description', 'Behavior video of animal moving in environment', ...
    'external_file', external_files, ...
    'data_unit', 'n/a', ...
    'format', 'external', ...
    'external_file_starting_frame', [0, 2], ...
    'timestamps', timestamps ...
);
nwb.acquisition.set('ExternalVideos', behavior_external_file);
%% Static images
% Static images can be stored in an <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/NWBFile.html 
% |*NWBFile*|> object using the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/RGBAImage.html 
% |*RGBAImage*|>, <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/RGBImage.html 
% |*RGBImage*|> or <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/GrayscaleImage.html 
% |*GrayscaleImage*|> classes. All of these image types provide an optional |description| 
% parameter to include text description about the image and the |resolution| parameter 
% to specify the pixels/cm resolution of the image.
% RGBAImage: for color images with transparency
% <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/RGBAImage.html 
% |*RGBAImage*|> is for storing data of color image with transparency. |data| 
% must be 3D where the first and second dimensions represent x and y. The third 
% dimension has length 4 and represents the RGBA value.

image_data = randi(255, [200, 200, 4], 'uint8');

rgba_image = types.core.RGBAImage( ...
    'data', reverseDims(image_data), ...  % required
    'resolution', 70.0, ...
    'description', 'RGBA image' ...
);
% RGBImage: for color images
% <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/RGBImage.html 
% |*RGBImage*|> is for storing data of RGB color image. |data| must be 3D where 
% the first and second dimensions represent x and y. The third dimension has length 
% 3 and represents the RGB value.

image_data = randi(255, [200, 200, 3], 'uint8');

rgb_image = types.core.RGBImage( ...
    'data', reverseDims(image_data), ...  % required
    'resolution', 70.0, ...
    'description', 'RGB image' ...
);
% *GrayscaleImage: for grayscale images*
% <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/GrayscaleImage.html 
% |*GrayscaleImage*|> is for storing grayscale image data. |data| must be 2D where 
% the first and second dimensions represent x and y.

image_data = randi(255, [200, 200], 'uint8');

grayscale_image = types.core.GrayscaleImage( ...
    'data', image_data, ...  % required
    'resolution', 70.0, ...
    'description', 'Grayscale image' ...
);
% Images: a container for images
% Add these images to an <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Images.html 
% |*Images*|> container that accepts any mix of these image types.

image_collection = types.core.Images( ...
    'description', 'A collection of images presented to the subject.'...
);

image_collection.baseimage.set('rgba_image', rgba_image);
image_collection.baseimage.set('rgb_image', rgb_image);
image_collection.baseimage.set('grayscale_image', grayscale_image);

nwb.acquisition.set('ImageCollection', image_collection);
%% IndexSeries for repeated images
% If the same images are presented multiple times, storing each copy in an <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ImageSeries.html 
% |*ImageSeries*|> would duplicate data. The <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/IndexSeries.html 
% |*IndexSeries*|> avoids this by referencing a set of unique images stored in 
% an <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Images.html 
% |*Images*|> container.
% 
% The <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Images.html 
% |*Images*|> container holds the unique images, and an <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ImageReferences.html 
% |*ImageReferences*|> object defines their order. The |data| field of <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/IndexSeries.html 
% |*IndexSeries*|> is a zero-based index into that order, indicating which image 
% is shown at each time point. |Timestamps| define when each indexed image was 
% presented.
% 
% For example, if <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/IndexSeries.html 
% |*IndexSeries*|>|.data| is |[0, 1, 0, 1]|, then the first and third presentations 
% use the first image in <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ImageReferences.html 
% |*ImageReferences*|>, and the second and fourth presentations use the second 
% image:

% Define images that were used for repeated presentations
rgb_image = imread('street2.jpg');
gray_image = uint8(mean(rgb_image, 3));

gs_street = types.core.GrayscaleImage(...
    'data', gray_image, ...
    'description', 'Grayscale image of a street.', ...
    'resolution', 28 ...
);
rgb_street = types.core.RGBImage( ...
    'data', reverseDims(rgb_image), ...
    'resolution', 28, ...
    'description', 'Color (rgb) image of a street.' ...
);

% Create an image collection with ordered images
image_order = types.core.ImageReferences(...
    'data', [types.untyped.ObjectView(rgb_street), types.untyped.ObjectView(gs_street)] ...
);
template_image_collection = types.core.Images( ...
    'gs_street', gs_street, ...
    'rgb_street', rgb_street, ...
    'description', 'A collection of images of a street.', ...
    'order_of_images', image_order ...
);

% The image collection is added to the stimulus_templates group
nwb.stimulus_templates.set('StreetImages', template_image_collection);

street_image_presentation = types.core.IndexSeries(...
    'description', 'Alternating presentation of color and grayscale versions of an image', ...
    'data', [0, 1, 0, 1], ... % NOTE: 0-indexed
    'indexed_images', template_image_collection, ...
    'timestamps', [0.1, 0.2, 0.3, 0.4] ...
)
nwb.stimulus_presentation.set('StreetImagePresentation', street_image_presentation);
%% 
% Here _data_ contains the (0-indexed) index of the displayed image as they 
% are ordered in the |ImageReference|.
%% Writing the images to an NWB File
% Now use <https://matnwb.readthedocs.io/en/latest/pages/functions/nwbExport.html 
% |*nwbExport*|> to write the <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/NWBFile.html 
% |*NWBFile*|> object and all its contents to disk:

nwbExport(nwb, "images_tutorial.nwb");
%% 
% This creates an NWB file containing the acquired image series, stimulus presentations, 
% static images, and any feature or index series you added.
% 
% You can reopen the file with |nwbRead| to verify its contents and check that 
% data shapes, timestamps, and metadata are as expected.