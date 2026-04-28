.. _images-tutorial:

Image Data
==========

.. image:: https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg
   :target: https://matlab.mathworks.com/open/github/v1?repo=NeurodataWithoutBorders/matnwb&file=tutorials/images.mlx
   :alt: Open in MATLAB Online
.. image:: https://img.shields.io/badge/View-Rendered_Live_Script-blue
   :target: ../../_static/html/tutorials/images.html
   :alt: View rendered Live Script


.. contents:: On this page
   :local:
   :depth: 2

In NWB, image data may be stored as collections of single images or as movie segments and can describe the subject, the environment, presented stimuli, or other experiment components. In this tutorial you will:

* Use `types.core.ImageSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ImageSeries.html>`_ to store acquired image series (movie segments).
* Use `types.core.OpticalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/OpticalSeries.html>`_ and `types.core.AbstractFeatureSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/AbstractFeatureSeries.html>`_ to store series of images or image features that were presented as stimuli.
* Use `types.core.GrayscaleImage <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/GrayscaleImage.html>`_, `types.core.RGBImage <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/RGBImage.html>`_ and `types.core.RGBAImage <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/RGBAImage.html>`_ to store static images.

**Preliminary note:** As described in the `dimensionMapNoDataPipes <dimensionMapNoDataPipes>`_ tutorial, when a MATLAB array is exported to HDF5, the dimensions of the array are reversed. Therefore, in order to correctly export the data, we will need to reverse the order of dimensions in image and timeseries data before adding these to NWB objects. The function below will be used for this purpose throughout the tutorial:

.. code-block:: matlab

   % Anonymous function for reversing data dimensions for NWB compliance
   reverseDims = @(data) permute(data, ndims(data):-1:1);

Create an NWB File
------------------

.. code-block:: matlab

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

.. code-block:: text

   nwb = 
     NwbFile with properties:
   
                                                nwb_version: '2.9.0'
                                           file_create_date: []
                                                 identifier: 'Mouse5_Day3'
                                        session_description: 'mouse in open exploration'
                                         session_start_time: {[2018-04-25T02:30:03.000000+02:00]}
                                  timestamps_reference_time: {[2018-04-25T03:00:45.000000+02:00]}
                                                acquisition: [0x1 types.untyped.Set]
                                                   analysis: [0x1 types.untyped.Set]
                                                    general: [0x1 types.untyped.Set]
                                    general_data_collection: ''
                                            general_devices: [0x1 types.untyped.Set]
                                     general_devices_models: [0x1 types.untyped.Set]
                             general_experiment_description: ''
                                       general_experimenter: 'LastName, FirstName'
                                general_extracellular_ephys: [0x1 types.untyped.Set]
                     general_extracellular_ephys_electrodes: []
                                        general_institution: 'University of My Institution'
                                general_intracellular_ephys: [0x1 types.untyped.Set]
        general_intracellular_ephys_experimental_conditions: []
                      general_intracellular_ephys_filtering: ''
       general_intracellular_ephys_intracellular_recordings: []
                    general_intracellular_ephys_repetitions: []
          general_intracellular_ephys_sequential_recordings: []
        general_intracellular_ephys_simultaneous_recordings: []
                    general_intracellular_ephys_sweep_table: []
                                           general_keywords: ''
                                                general_lab: ''
                                              general_notes: ''
                                       general_optogenetics: [0x1 types.untyped.Set]
                                     general_optophysiology: [0x1 types.untyped.Set]
                                       general_pharmacology: ''
                                           general_protocol: ''
                               general_related_publications: 'DOI:10.1016/j.neuron.2016.12.011'
                                         general_session_id: 'session_1234'
                                             general_slices: ''
                                      general_source_script: ''
                            general_source_script_file_name: ''
                                           general_stimulus: ''
                                            general_subject: []
                                            general_surgery: ''
                                              general_virus: ''
                                   general_was_generated_by: ''
                                                  intervals: [0x1 types.untyped.Set]
                                           intervals_epochs: []
                                    intervals_invalid_times: []
                                           intervals_trials: []
                                                 processing: [0x1 types.untyped.Set]
                                                    scratch: [0x1 types.untyped.Set]
                                      stimulus_presentation: [0x1 types.untyped.Set]
                                         stimulus_templates: [0x1 types.untyped.Set]
                                                      units: []

Subject Information
~~~~~~~~~~~~~~~~~~~

It is recommended to store information about the experimental subject in the file. Create a `Subject <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Subject.html>`_ object to store metadata about the subject, then assign it to ``nwb.general_subject``.

.. code-block:: matlab

   subject = types.core.Subject( ...
       'subject_id', '005', ...
       'age', 'P90D', ...
       'description', 'mouse 5', ...
       'species', 'Mus musculus', ...
       'sex', 'M' ...
   );
   nwb.general_subject = subject;

ImageSeries: Storing series of images as acquisition
----------------------------------------------------

`ImageSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ImageSeries.html>`_ is a general container for time series of images acquired during an experiment. Image data can be stored directly in the NWB file or referenced from external image files (see section External files below). For color images stored in the NWB file, the channel order must be RGB.

.. code-block:: matlab

   image_data = randi(255, [200, 50, 50, 3], 'uint8');
   behavior_images = types.core.ImageSeries( ...
       'data', reverseDims(image_data), ...
       'description', 'Image data of an animal in the environment', ...
       'data_unit', 'n.a.', ...
       'starting_time_rate', 1.0, ...
       'starting_time', 0.0 ...
   );
   
   nwb.acquisition.set('ImageSeries', behavior_images);

OpticalSeries: Storing series of images as stimuli
--------------------------------------------------

We will use the `OpticalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/OpticalSeries.html>`_ class to store time series of images presented to the subject as stimuli. The `OpticalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/OpticalSeries.html>`_ class extends the ImageSeries with additional fields that describe the spatial relationship between the subject and the stimuli, such as:

* ``field_of_view`` – physical extent of the image in the visual field or target area.
* ``distance`` – distance from the image source to the subject.

Here we create an `OpticalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/OpticalSeries.html>`_ named ``StimulusPresentation`` containing synthetic RGB image data (As in all `TimeSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/TimeSeries.html>`_, the first dimension is time. The second and third dimensions represent x and y and the fourth dimension represents the RGB value (length of 3) for color images):

.. code-block:: matlab

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

AbstractFeatureSeries: Storing features of visual stimuli
---------------------------------------------------------

While full image data is usually stored in an `OpticalSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/OpticalSeries.html>`_, you can also store derived features of the visual stimuli—either instead of, or in addition to, the raw images. Examples of derived features include **mean luminance**, **contrast**, or **spatial frequency**. The `AbstractFeatureSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/AbstractFeatureSeries.html>`_ class is a general ``TimeSeries`` container for storing such feature data over time.

.. code-block:: matlab

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

External files
--------------

External files (e.g., videos of the behaving animal) can be added to an `NWBFile <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/NWBFile.html>`_ by creating an `ImageSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ImageSeries.html>`_ with the ``external_file`` field set to the relative path(s) of the file(s) on disk. The path must be relative to the NWB file’s location.

Either ``external_file`` **or** ``data`` must be specified — not both. ``external_file`` can be a cell array of multiple video files.

The ``starting_frame`` attribute is a zero-based index into the full ``ImageSeries`` that indicates the first frame contained in each file listed in ``external_file``. For example, if three files contain 5, 10, and 20 frames respectively, ``starting_frame`` would be ``[0, 5, 15]``. If one file contains all frames, it is ``[0]``. This indexing allows random access to frames without loading all preceding files.

.. code-block:: matlab

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

.. code-block:: text

   Warning: The property "data_unit" of type "types.core.ImageSeries" depends on the property "data", which is unset. If you do not set a value for "data, the value of "data_unit" will not be exported to file.

.. code-block:: matlab

   nwb.acquisition.set('ExternalVideos', behavior_external_file);

Static images
-------------

Static images can be stored in an `NWBFile <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/NWBFile.html>`_ object using the `RGBAImage <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/RGBAImage.html>`_, `RGBImage <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/RGBImage.html>`_ or `GrayscaleImage <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/GrayscaleImage.html>`_ classes. All of these image types provide an optional ``description`` parameter to include text description about the image and the ``resolution`` parameter to specify the pixels/cm resolution of the image.

RGBAImage: for color images with transparency
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

`RGBAImage <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/RGBAImage.html>`_ is for storing data of color image with transparency. ``data`` must be 3D where the first and second dimensions represent x and y. The third dimension has length 4 and represents the RGBA value.

.. code-block:: matlab

   image_data = randi(255, [200, 200, 4], 'uint8');
   
   rgba_image = types.core.RGBAImage( ...
       'data', reverseDims(image_data), ...  % required
       'resolution', 70.0, ...
       'description', 'RGBA image' ...
   );

RGBImage: for color images
~~~~~~~~~~~~~~~~~~~~~~~~~~

`RGBImage <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/RGBImage.html>`_ is for storing data of RGB color image. ``data`` must be 3D where the first and second dimensions represent x and y. The third dimension has length 3 and represents the RGB value.

.. code-block:: matlab

   image_data = randi(255, [200, 200, 3], 'uint8');
   
   rgb_image = types.core.RGBImage( ...
       'data', reverseDims(image_data), ...  % required
       'resolution', 70.0, ...
       'description', 'RGB image' ...
   );

**GrayscaleImage: for grayscale images**
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

`GrayscaleImage <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/GrayscaleImage.html>`_ is for storing grayscale image data. ``data`` must be 2D where the first and second dimensions represent x and y.

.. code-block:: matlab

   image_data = randi(255, [200, 200], 'uint8');
   
   grayscale_image = types.core.GrayscaleImage( ...
       'data', image_data, ...  % required
       'resolution', 70.0, ...
       'description', 'Grayscale image' ...
   );

Images: a container for images
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Add these images to an `Images <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Images.html>`_ container that accepts any mix of these image types.

.. code-block:: matlab

   image_collection = types.core.Images( ...
       'description', 'A collection of images presented to the subject.'...
   );
   
   image_collection.baseimage.set('rgba_image', rgba_image);
   image_collection.baseimage.set('rgb_image', rgb_image);
   image_collection.baseimage.set('grayscale_image', grayscale_image);
   
   nwb.acquisition.set('ImageCollection', image_collection);

IndexSeries for repeated images
-------------------------------

If the same images are presented multiple times, storing each copy in an `ImageSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ImageSeries.html>`_ would duplicate data. The `IndexSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/IndexSeries.html>`_ avoids this by referencing a set of unique images stored in an `Images <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Images.html>`_ container.

The `Images <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/Images.html>`_ container holds the unique images, and an `ImageReferences <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ImageReferences.html>`_ object defines their order. The ``data`` field of `IndexSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/IndexSeries.html>`_ is a zero-based index into that order, indicating which image is shown at each time point. ``timestamps`` define when each indexed image was presented.

For example, if the ``data`` property of `IndexSeries <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/IndexSeries.html>`_ is ``[0, 1, 0, 1]``, then the first and third presentations use the first image in `ImageReferences <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/ImageReferences.html>`_, and the second and fourth presentations use the second image:

.. code-block:: matlab

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

.. code-block:: text

   street_image_presentation = 
     IndexSeries with properties:
   
            indexed_images: [1x1 types.untyped.SoftLink]
        indexed_timeseries: []
        starting_time_unit: 'seconds'
       timestamps_interval: 1
           timestamps_unit: 'seconds'
                      data: [0 1 0 1]
                 data_unit: 'N/A'
                  comments: 'no comments'
                   control: []
       control_description: ''
           data_continuity: ''
           data_conversion: 1
               data_offset: 0
           data_resolution: -1
               description: 'Alternating presentation of color and grayscale versions of an image'
             starting_time: []
        starting_time_rate: []
                timestamps: [0.1000 0.2000 0.3000 0.4000]

.. code-block:: matlab

   nwb.stimulus_presentation.set('StreetImagePresentation', street_image_presentation);

Here *data* contains the (0-indexed) index of the displayed image as they are ordered in the ``ImageReference``.

Writing the images to an NWB File
---------------------------------

Now use `nwbExport <https://matnwb.readthedocs.io/en/latest/pages/functions/nwbExport.html>`_ to write the `NWBFile <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/NWBFile.html>`_ object and all its contents to disk:

.. code-block:: matlab

   nwbExport(nwb, "images_tutorial.nwb");

This creates an NWB file containing the acquired image series, stimulus presentations, static images, and any feature or index series you added.

You can reopen the file with ``nwbRead`` to verify its contents and check that data shapes, timestamps, and metadata are as expected.
