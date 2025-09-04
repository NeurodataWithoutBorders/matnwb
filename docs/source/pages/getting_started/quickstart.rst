.. _quickstart-tutorial:

Quickstart: Read and write NWB files
====================================


Goal
----

This tutorial walks you step-by-step through creating, writing, and reading a minimal NWB file with MatNWB. It is designed to be a short, learning-oriented introduction.


Prerequisites
-------------

- MATLAB R2019b or later  
- MatNWB :ref:`installed<installation>` and added to your MATLAB path  


Step 1 — Create a minimal NWB file
----------------------------------

An NWB file always needs three required fields:

- ``identifier`` (unique ID)  
- ``session_description`` (short text summary)  
- ``session_start_time`` (timestamp of the session start)  

.. code-block:: matlab

   nwb = NwbFile( ...
       'identifier', 'quickstart-demo-20250411T153000Z', ...
       'session_description', 'Quickstart demo session', ...
       'session_start_time', datetime(2025,4,11,15,30,0,'TimeZone','UTC'));


Step 2 — Add a TimeSeries
-------------------------

We’ll add a short synthetic signal sampled at 10 Hz for 1 second using the :class:`types.core.TimeSeries` neurodata type.

.. code-block:: matlab

   t = 0:0.1:0.9;        % 10 time points
   data = sin(2*pi*1*t); % simple sine wave

   ts = types.core.TimeSeries( ...
       'data', data, ...
       'data_unit', 'arbitrary', ...
       'starting_time', 0.0, ...
       'starting_time_rate', 10.0);

   nwb.acquisition.set('DemoSignal', ts);

.. note::
   MatNWB uses MATLAB array ordering when writing to HDF5. For multi-dimensional time series, the time dimension should be the last dimension of the MATLAB array. See the :doc:`Data Dimensions </pages/concepts/considerations>` section in the "MatNWB important considerations" page.


Step 3 — Write the File
-----------------------

.. code-block:: matlab

   nwbExport(nwb, 'quickstart_demo.nwb', 'owerwrite');

This writes the NWB file to your current working directory.

Step 4 — Read the File Back
---------------------------

.. code-block:: matlab

   nwb_in = nwbRead('quickstart_demo.nwb');

Confirm that the ``DemoSignal`` was written and read back:

.. code-block:: matlab

   ts_in = nwb_in.acquisition.get('DemoSignal');

   % Data is a DataStub (lazy loading). Index like an array or load fully:
   first_five = ts_in.data(1:5);     % reads a slice
   all_data   = ts_in.data.load();   % reads all values


That’s it!
----------

You have written and read an NWB file with MatNWB.

Next steps
----------

- Try the :doc:`Introduction Tutorial <../tutorials/intro>` for a full example with subject metadata, events, and processed data.
- Learn how to read more complex files: :doc:`Reading files with MatNWB <../tutorials/read_demo>`.
- Explore the `MatNWB API reference <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/core/index.html>`_.
