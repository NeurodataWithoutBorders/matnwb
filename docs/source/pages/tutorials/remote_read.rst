.. _remote_read-tutorial:

Reading NWB Files from Remote Locations
=======================================

.. image:: https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg
   :target: https://matlab.mathworks.com/open/github/v1?repo=NeurodataWithoutBorders/matnwb&file=tutorials/remote_read.mlx
   :alt: Open in MATLAB Online
.. image:: https://img.shields.io/badge/View-Rendered_Live_Script-blue
   :target: ../../_static/html/tutorials/remote_read.html
   :alt: View rendered Live Script


.. contents:: On this page
   :local:
   :depth: 2

It is possible to read an NWB file (or any HDF5 file) in MATLAB directly from several different kinds of remote locations, including AWS, Azure Blob Storage and HDFS. This tutorial will walk you through specifically loading a MATLAB file from AWS S3, which is the storage used by the DANDI archive. See `MATLAB documentation <https://www.mathworks.com/help/matlab/ref/h5read.html>`_ for more general information.

To read an NWB file file from an s3 store, first you need to figure out the s3 path of that resource. The easiest way to do this is to use the DANDI web client.

* (skip if on DANDI Hub) Make sure you do not have a file ``~/.aws/credentials``. If you do, rename it to something else. On Windows this file would be somewhere like ``C:/Users/username/.aws/credentials``.
* Find and select a dandiset you want on the `DANDI Archive <https://dandiarchive.org/dandiset>`_, then click

   .. image:: ../../_static/tutorials/media/remote_read/image_0.png
      :class: tutorial-media
      :width: 121px
      :alt: image_0.png
* Navigate to the NWB file of interest and click

   .. image:: ../../_static/tutorials/media/remote_read/image_1.png
      :class: tutorial-media
      :width: 30px
      :alt: image_1.png
* Find the second entry of "contentURL"

   .. image:: ../../_static/tutorials/media/remote_read/image_2.png
      :class: tutorial-media
      :width: 688px
      :alt: image_2.png
* In your MATLAB session, take the end of that url (the blob id) and add it to this expression: ``s3 = 's3://dandiarchive/blobs/<blob_id>'``. In this case, you would have:
* Use ``setenv`` to specify AWS region. The DandiArchive datasets are located on ``us-east-2``

.. code-block:: matlab

   % Example S3 path for a 380KiB file from dandiset 001199:
   s3 = "s3://dandiarchive/blobs/3fb/2c8/3fb2c8b9-26db-47c0-86c2-9594678a8263";
   
   % Set AWS region (NB: Changes environment variable)
   setenv('AWS_DEFAULT_REGION', 'us-east-2') 

* Read from that s3 path directly with:

.. code-block:: matlab

   nwbfile = nwbRead(s3) % this may take a minute

.. code-block:: text

   nwbfile = 
     NwbFile with properties:
   
                                                nwb_version: '2.6.0'
                                           file_create_date: [1x1 types.untyped.DataStub]
                                                 identifier: 'BH590_30_200_67_15_NZ'
                                        session_description: 'Neural Spikes for neural pathways to tFUS'
                                         session_start_time: 2024-08-16T20:02:00.000000-04:00
                                  timestamps_reference_time: 2024-09-30T18:09:15.858000-04:00
                                                acquisition: [0x1 types.untyped.Set]
                                                   analysis: [0x1 types.untyped.Set]
                                                    general: [0x1 types.untyped.Set]
                                    general_data_collection: 'tFUS parameters {PRF:30Hz PD:200us UD:67ms PRESSURE:67V}'
                                            general_devices: [1x1 types.untyped.Set]
                             general_experiment_description: ''
                                       general_experimenter: ''
                                general_extracellular_ephys: [1x1 types.untyped.Set]
                     general_extracellular_ephys_electrodes: [1x1 types.hdmf_common.DynamicTable]
                                        general_institution: 'Carnegie Mellon University'
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
                                              general_notes: 'Recording:S1; stim at:S1'
                                       general_optogenetics: [0x1 types.untyped.Set]
                                     general_optophysiology: [0x1 types.untyped.Set]
                                       general_pharmacology: ''
                                           general_protocol: ''
                               general_related_publications: ''
                                         general_session_id: ''
                                             general_slices: ''
                                      general_source_script: ''
                            general_source_script_file_name: ''
                                           general_stimulus: 'intervals contains each tFUS trial start and end timestamps'
                                            general_subject: [1x1 types.core.Subject]
                                            general_surgery: ''
                                              general_virus: ''
                                                  intervals: [0x1 types.untyped.Set]
                                           intervals_epochs: []
                                    intervals_invalid_times: []
                                           intervals_trials: [1x1 types.core.TimeIntervals]
                                                 processing: [0x1 types.untyped.Set]
                                                    scratch: [0x1 types.untyped.Set]
                                      stimulus_presentation: [0x1 types.untyped.Set]
                                         stimulus_templates: [0x1 types.untyped.Set]
                                                      units: [1x1 types.core.Units]

That's it! MATLAB will automatically detect that this is an S3 path instead of a local filepath and will set up a remote read interface for that NWB file. This approach works on any computer with a fairly recent version of MATLAB and an internet connection. It works particularly well on the `DANDI Hub <http://hub.dandiarchive.org>`_, which has a very fast connection to the DANDI S3 store and which provides a MATLAB environment for free provided you have a license.

Note: MATLAB vs. Python remote read
-----------------------------------

Python also allows you to remotely read a file, and has several advantages over MATLAB. Reading in Python is faster. On DANDI Hub, for MATLAB, reading the file takes about 51 seconds, while the analogous operation takes less than a second in Python. Python also allows you to create a local cache so you are not repeatedly requesting the same data, which can further speed up data access. Overall, we recommend remote reading using Python instead of MATLAB.
