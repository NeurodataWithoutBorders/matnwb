.. _howto-compression-profiles:

Use compression profiles
========================

How to optimize storage in NWB files using predefined or custom dataset configuration profiles for compression and chunking.

Prerequisites
-------------
* MatNWB installed and on the MATLAB path.
* Basic familiarity with creating NWB objects (see the MatNWB tutorials if needed).

.. contents:: On this page
	:local:
	:depth: 2

At a glance
-----------
1. Create or load your ``NwbFile`` and populate data.
2. Read a dataset configuration profile (``default``, ``cloud``, or ``archive`` – or your own).
3. Apply it with :func:`io.config.applyDatasetConfiguration`.
4. Export.


Creating and exporting an NWB file with a profile
-------------------------------------------------
.. code-block:: matlab

	% 1. Create and populate an NWB file
	nwb = NwbFile();  % (set identifiers, session start time, etc.)
	data = rand(1e6, 1, 'single');  % Example large vector
	es = types.core.ElectricalSeries(...
		 'data', data, ...
		 'data_unit', 'volts', ...
		 'starting_time', 0, ...
		 'starting_time_rate', 30000);
	nwb.acquisition.set('ExampleSeries', es);

	% 2. Load a profile (choose "default", "cloud", or "archive")
	cfg = io.config.readDatasetConfiguration("cloud");

	% 3. Apply it (wraps large numeric datasets in DataPipe objects)
	io.config.applyDatasetConfiguration(nwb, cfg);

	% 4. Export
	nwbExport(nwb, 'example_cloud_profile.nwb');


Overriding an existing DataPipe
-------------------------------
If you already created a ``DataPipe`` manually (or ran a profile once) and want to re‑apply with a different profile:

.. code-block:: matlab

	newCfg = io.config.readDatasetConfiguration("archive");
	io.config.applyDatasetConfiguration(nwb, newCfg, "OverrideExisting", true);

Customizing a profile
---------------------

1. Copy one of the shipped JSON files (e.g. ``default_dataset_configuration.json``) to a new file in ``configuration/`` (e.g. ``myprofile_dataset_configuration.json``).

2. Adjust fields:

   ``chunking.target_chunk_size``
       Overall byte target size for each chunk.

   ``chunking.strategy_by_rank``
       Strategy per dataset rank (key = number of dimensions).
       Each list element corresponds to a dimension axis.
       Possible values:

       - ``"flex"``
       - ``"max"``
       - *integer* (upper bound)

   ``compression.method``
       Compression algorithm: ``deflate`` (gzip), ``ZStandard`` (if available), or a custom filter ID.

   ``compression.parameters.level``
       Integer compression level (method-dependent).

   ``compression.prefilters``
       Optional prefilters, e.g. ``["shuffle"]``.

3. Add any neurodata type/dataset-specific overrides. Key format examples:

   ``"ElectricalSeries/data"``
       Targets the ``data`` dataset inside any ``ElectricalSeries``.

   ``"TwoPhotonSeries/data"``
       Targets the ``data`` dataset inside any ``TwoPhotonSeries``.


4. Load it:

.. code-block:: matlab

	cfg = io.config.readDatasetConfiguration("myprofile");
	io.config.applyDatasetConfiguration(nwb, cfg);


Verifying the applied configuration
----------------------------------
After export, you can inspect chunking and compression with ``h5info``:

.. code-block:: matlab

	info = h5info('example_cloud_profile.nwb', '/acquisition/ExampleSeries/data');
	info.ChunkSize   % should reflect computed chunkSize
	info.Filters     % lists compression + shuffle if present

Troubleshooting
---------------
* ``No matching rank strategy`` error: Add a list for that rank (e.g. key ``"5"``) in ``strategy_by_rank``.
* ``TargetSizeExceeded`` warning: Reduce dimensions marked ``max`` or lower numeric bounds; lower ``target_chunk_size``.
* ``Unsupported target_chunk_size_unit``: Ensure unit is one of ``bytes``, ``kiB``, ``MiB``, ``GiB``.

Next steps
----------
* Combine with streaming writes using ``DataPipe.append`` for very large, incremental acquisitions.
* Profile read performance with different chunk strategies to tune domain‑specific workloads.

Summary
-------
You load a profile JSON, apply it, and export. MatNWB computes chunk sizes from simple declarative rules (``flex`` / ``max`` / numeric) and attaches compression filters. This yields consistent, reproducible storage characteristics across NWB files without hand‑tuning each dataset.


See also:
---------
:ref:`Storage optimization <pages/concepts/file_create/performance_optimization>`.
