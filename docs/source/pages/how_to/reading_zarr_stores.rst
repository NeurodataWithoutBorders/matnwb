.. _how_to_reading_zarr_stores:

Reading NWB Files Stored as Zarr
================================

This guide shows you how to read an NWB file that is stored as a Zarr v3 store, from disk or from a web server, with :func:`nwbRead`.

.. contents::
   :local:
   :depth: 2

What a Zarr store is
--------------------

Besides HDF5, an NWB file can be stored as a Zarr store: a directory of JSON metadata files and chunk files, conventionally named with a ``.zarr`` or ``.nwb.zarr`` suffix. PyNWB writes one through `hdmf-zarr <https://hdmf-zarr.readthedocs.io>`_. Because the store is a directory of small files, it can also be served from a web server and read in place over HTTP.

MatNWB reads Zarr v3 stores written by hdmf-zarr 0.14 or newer. Writing them is not supported: :func:`nwbExport` writes HDF5 files.

Prerequisites
-------------

Reading a Zarr store needs MATLAB R2023a or newer and two MATLAB packages that are installed separately from MatNWB. See :ref:`installation-zarr`.

Reading a store from disk
-------------------------

Pass the store directory to :func:`nwbRead` as you would pass an HDF5 file. The backend is detected from the store's metadata:

.. code-block:: MATLAB

    nwb = nwbRead("session.nwb.zarr");

The result is the same :class:`NwbFile` you get from an HDF5 file. Links, object references, compound datasets and ragged table columns resolve the way they do for HDF5, and datasets are lazy: indexing a :ref:`DataStub <matnwb-read-untyped-datastub-datapipe>` reads only the chunks that hold the selection.

.. code-block:: MATLAB

    raw = nwb.acquisition.get('raw');
    firstSamples = raw.data(:, 1:1000);   % reads only the chunks holding these samples

Reading a store from a web server
---------------------------------

A store that is served over http(s) is read from its URL:

.. code-block:: MATLAB

    nwb = nwbRead("https://example.org/data/session.nwb.zarr");

Opening the store fetches its metadata and the small arrays MatNWB needs while it parses the file. Everything else stays on the server until you index it, so a few samples of a large dataset cost one request per chunk rather than a download of the dataset.

A web server cannot list a directory, so a store is read over HTTP through the consolidated metadata at its root, which hdmf-zarr writes when it saves a file.

Choosing the backend explicitly
-------------------------------

:func:`nwbRead` detects HDF5 files and Zarr stores from their contents. To require one backend, pass the ``StorageBackend`` option. It errors when the path is not of that kind:

.. code-block:: MATLAB

    nwb = nwbRead("session.nwb.zarr", "StorageBackend", "zarr3");

Limitations
-----------

- Zarr v2 stores, written by hdmf-zarr before 0.14, are not supported. hdmf-zarr 0.14 provides ``NWBZarrV2IO.convert_to_v3`` to convert them.
- Writing Zarr stores is not supported.
- An object reference that points into another store is not supported.
- hdmf-zarr compresses data with ``zstd`` by default, and zarr-matlab decodes ``zstd`` through compiled codecs, see :ref:`installation-zarr`. Without them, reading stops at the first ``zstd``-compressed dataset with an error naming the missing codec.
