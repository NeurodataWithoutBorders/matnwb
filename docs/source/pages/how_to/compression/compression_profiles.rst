.. _howto-compression-profiles:

How to apply compression & chunking profiles when writing NWB files
===================================================================

This how-to shows you, step by step, how to apply a predefined (or custom) dataset
configuration profile (chunking + compression) to the datasets in an ``NwbFile``
before exporting with :func:`nwbExport`. It focuses on the practical steps – *what to do* –
and assumes you already know in general why chunking and compression matter (see the
:doc:`performance optimization </pages/concepts/file_create/performance_optimization>`).

.. contents:: On this page
	:local:
	:depth: 2

At a glance
-----------
1. Create or load your ``NwbFile`` and populate data.
2. Read a dataset configuration profile (``default``, ``cloud``, or ``archive`` – or your own).
3. Apply it with :func:`io.config.applyDatasetConfiguration`.
4. Export.

When to use this
----------------
Use this whenever you have medium/large numeric datasets and you want:

* Reasonable default gzip (deflate) compression and adaptive chunk sizes (``default``).
* Cloud‑optimized access patterns (smaller per-chunk footprint + shuffle) (``cloud``).
* Higher compression ratio for long‑term storage (larger chunk targets + Zstandard) (``archive``).

Prerequisites
-------------
* MatNWB installed and on the MATLAB path.
* Basic familiarity with creating NWB objects (see the MatNWB tutorials if needed).

Key functions & files
---------------------
* ``io.config.readDatasetConfiguration(profile)`` – loads JSON from ``configuration/*_dataset_configuration.json``.
* ``io.config.applyDatasetConfiguration(nwb, config, "OverrideExisting", false)`` – wraps qualifying numeric arrays in ``types.untyped.DataPipe`` with computed ``chunkSize`` and compression filters.
* Configuration JSON examples (shipped):

  - ``configuration/default_dataset_configuration.json``
  - ``configuration/cloud_dataset_configuration.json``
  - ``configuration/archive_dataset_configuration.json``

Quick start example
-------------------
.. code-block:: matlab

	% 1. Create and populate an NWB file
	nwb = NwbFile();  % (set identifiers, session start time, etc.)
	data = rand(1e6,1,'single');  % Example large vector
	es = types.core.ElectricalSeries(...
		 'data', data, ...
		 'data_unit', 'volts', ...
		 'starting_time', 0, ...
		 'starting_time_rate', 30000);
	nwb.acquisition.set('example_eSeries', es);

	% 2. Load a profile (choose "default", "cloud", or "archive")
	cfg = io.config.readDatasetConfiguration("cloud");

	% 3. Apply it (wraps large numeric datasets in DataPipe objects)
	io.config.applyDatasetConfiguration(nwb, cfg);

	% 4. Export
	nwbExport(nwb, 'example_cloud_profile.nwb');

What happens under the hood?
----------------------------
``applyDatasetConfiguration`` walks every neurodata object in the file tree and, for each numeric dataset:

* Resolves the most specific matching entry in the configuration (dataset‑level override beats ``Default``).
* Computes a target ``chunkSize`` given:
  - ``chunking.target_chunk_size`` + ``target_chunk_size_unit`` (e.g. 1,000,000 bytes)
  - ``chunking.strategy_by_rank`` list for the dataset’s rank (e.g. ["flex", "max"]).
	 * ``flex`` → dimension is sized so total bytes per chunk ≈ target.
	 * ``max`` → take full length of that dimension.
	 * Numeric value → upper bound (capped by actual size).
* Chooses compression:
  - ``method = deflate`` (gzip) → uses ``compressionLevel`` (default 3 if absent).
  - Other methods (e.g. ``ZStandard``) → inserted as a custom filter.
  - Optional ``prefilters`` like ``shuffle`` improve compression on integer / low‑entropy columns.
* Replaces the raw numeric array with a ``types.untyped.DataPipe`` configured with ``chunkSize``, compression filters, and (for vectors) a columnar representation (``maxSize = Inf`` ensures 1‑D write layout).

Selecting a profile
-------------------
Profile comparison (conceptual):

* ``default``: Balanced; small (1 MB) target chunks, gzip level 3.
* ``cloud``: Slightly larger chunks (10 MB) + shuffle for better remote object store streaming; dataset‑specific override for ``ElectricalSeries/data`` to bound one dimension (e.g. 64 samples per chunk row) aiding partial reads.
* ``archive``: Large target (100 MB) to improve compression ratio, Zstandard level 5 (faster decompression than high‑level gzip for similar ratios). Good for cold storage.

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

	* ``chunking.target_chunk_size`` / ``_unit``: Overall chunk byte target.
	* ``chunking.strategy_by_rank``: For each rank (key is the number of dimensions). Each list position corresponds to a dimension (slowest → fastest in MATLAB order). Use:
	  - ``"flex"``
	  - ``"max"``
	  - an integer (upper bound)
	* ``compression.method``: ``deflate`` (gzip), ``ZStandard`` (if filter available), or a custom filter ID.
	* ``compression.parameters.level``: Integer compression level (method‑dependent).
	* ``compression.prefilters``: e.g. ``["shuffle"]``.
3. Add any dataset‑specific overrides. Key format examples:

	* ``"ElectricalSeries/data"`` – targets the ``data`` dataset inside any ``ElectricalSeries``.
	* ``"ProcessingModule_TimeIntervals_start_time"`` (illustrative) – keys are matched to MATLAB property / spec paths (see comments below).

4. Load it:

.. code-block:: matlab

	cfg = io.config.readDatasetConfiguration("myprofile");
	io.config.applyDatasetConfiguration(nwb, cfg);

Dataset override resolution
---------------------------
The resolver looks for the most specific key that matches the dataset’s path/type; if no specific key matches, it falls back to ``Default``. You can safely omit fields you don’t change in an override; only provided subfields (e.g. updating ``chunking.strategy_by_rank``) are merged.

Edge cases & tips
-----------------
* Small datasets: If the whole dataset fits within the target chunk size threshold, no ``DataPipe`` is created (stored contiguous by default); this avoids unnecessary chunking overhead.
* Non‑numeric datasets: Currently ignored by the automatic wrapper (e.g. ragged arrays, DataStubs, Sets). You can still wrap them manually.
* Reading existing NWB (``nwbRead``): Re‑chunking or re‑compressing existing datasets into a new output file is planned but not yet implemented for ``DataStub`` sources.
* Vectors: Are represented as true 1‑D in HDF5 (MatNWB sets ``maxSize = Inf`` to maintain extendability / column layout).
* Warnings: If actual computed chunk size bytes exceed the requested target, a warning is raised – adjust strategy or target size.

Verifying the applied configuration
----------------------------------
After export, you can inspect chunking and compression with ``h5info``:

.. code-block:: matlab

	info = h5info('example_cloud_profile.nwb', '/acquisition/example_eSeries/data');
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

See also
--------
* :func:`io.config.readDatasetConfiguration`
* :func:`io.config.applyDatasetConfiguration`
* :func:`nwbExport`
* HDF5 chunking & compression guidelines (HDF Group docs)

