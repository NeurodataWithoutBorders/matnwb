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
2. Choose dataset settings: a built-in profile, a custom JSON file, or a struct already in memory.
3. Apply them with :meth:`NwbFile.applyDatasetSettings` (or let :func:`nwbExport` do it for you).
4. Export.


Creating and exporting an NWB file with a configuration profile
---------------------------------------------------------------
.. code-block:: matlab

	% 1. Create and populate an NWB file
	nwb = NwbFile( ...
        'identifier', 'compression-howto-20250411T153000Z', ...
        'session_description', 'Compression profile how-to guide', ...
        'session_start_time', datetime(2025,4,11,15,30,0,'TimeZone','UTC'));
	data = rand(32, 1e6, 'single');  % Example large matrix
	es = types.core.TimeSeries(...
		 'data', data, ...
		 'data_unit', 'volts', ...
		 'starting_time', 0, ...
		 'starting_time_rate', 30000);
	nwb.acquisition.set('ExampleSeries', es);

	% 2. Apply the cloud profile (convenience method accepts profile name,
	%    JSON file path, or a configuration struct)
	nwb.applyDatasetSettingsProfile('cloud');

	% 3. Export (settings already applied in-place)
	nwbExport(nwb, 'example_cloud_profile.nwb');

	% -- OR -- apply settings on the fly when exporting
	% nwbExport(nwb, 'example_cloud_profile.nwb', ...
	%     'DatasetSettingsProfile', 'cloud');


Overriding an existing DataPipe
-------------------------------
If you already created a ``DataPipe`` manually (or ran a profile once) and want to re‑apply with a different profile:

.. code-block:: matlab

	nwb.applyDatasetSettings('archive', "OverrideExisting", true);

Customizing a profile
---------------------

1. Copy one of the shipped JSON files (e.g. ``default_dataset_configuration.json``) to a new file (e.g. ``configuration/myprofile_dataset_configuration.json``).

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


4. Load it (either via the helper or by passing the file path directly):

.. code-block:: matlab


	% Apply configuration from file to the NwbFile object
	nwb.applyDatasetSettings('configuration/myprofile_dataset_configuration.json');


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
:doc:`Storage optimization </pages/concepts/file_create/storage_optimization>`.
