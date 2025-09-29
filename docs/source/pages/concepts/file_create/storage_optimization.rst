
Storage optimization
====================

Neuroscience data can be very large, and compression helps reduce file size, improving both storage efficiency and data transfer time.


Compression
-----------

MatNWB supports HDF5 compression filters via the :class:`types.untyped.DataPipe` class. The default filter is GZIP (also known as DEFLATE), which is widely supported and provides a good balance of compression ratio and speed. Custom or dynamically loaded filters (e.g., BLOSC, LZ4) can be configured when the underlying HDF5 build supports them—see the :doc:`dynamically loaded filters </pages/tutorials/dynamically_loaded_filters>` tutorial. These can offer better performance for specific data types or access patterns, however they may not be as widely supported as GZIP. In other words, if you use a custom filter, ensure that any software or collaborators accessing the file can support that filter.

For step-by-step usage, see the :doc:`DataPipe tutorial </pages/tutorials/dataPipe>` and the dynamically loaded filter example (:doc:`dynamically loaded filters </pages/tutorials/dynamically_loaded_filters>`).


Chunking
--------

A prerequisite for compression is chunking. Chunking is the partitioning of datasets into fixed-size blocks, which are stored and accessed independently. If the full dataset were stored as a single contiguous block, compression would be ineffective for partial reads/writes. That's why chunking is essential for enabling compression, as well as for efficient I/O of large datasets. Choosing optimal chunk sizes and shapes is important for performance, and should be based on expected access patterns.

For example, if you frequently read time series data in segments (e.g., 1-second windows), chunking along the time axis with a size that matches your typical read length can improve performance. Similarly, for image data, chunking in spatial blocks that align with common access patterns (e.g., tiles or frames) can be beneficial.

Further, the chunk size can impact compression efficiency. Larger chunks may yield better compression ratios, but can also increase memory usage during read/write operations. Conversely, smaller chunks may reduce memory overhead but could lead to less effective compression. For archival purposes, larger chunks are often preferred to maximize compression, while for interactive analysis, smaller chunks may be more suitable to optimize access speed. For online/cloud access, chunk sizes in the range of 2MB to 10MB are often recommended, but this can vary based on specific use cases and data characteristics.


MatNWB configuration profiles
-----------------------------
MatNWB provides predefined configuration profiles that set sensible defaults for chunking and compression based on common use cases. These profiles can be specified when creating an NWB file, allowing users to optimize their files for local storage, cloud storage, or archiving without needing to manually configure each parameter.

Profile comparison:
~~~~~~~~~~~~~~~~~~~

* **default**: Balanced; small (1 MB) target chunks, gzip level 3.
* **cloud**: Slightly larger chunks (10 MB) + shuffle for better remote object store streaming; dataset‑specific override for ``ElectricalSeries/data`` to bound one dimension (e.g. 64 samples per chunk row) aiding partial reads.
* **archive**: Large target (100 MB) to improve compression ratio, Zstandard level 5 (faster decompression than high‑level gzip for similar ratios). Good for cold storage.

See the :doc:`compression profiles </pages/how_to/compression/compression_profiles>` guide for details on using these profiles, as well as how to create custom configurations tailored to your specific needs.


MatNWB tutorials & references
-----------------------------

- Tutorial: :doc:`DataPipe </pages/tutorials/dataPipe>` (practical usage patterns)
- Tutorial: :doc:`dynamically loaded filters </pages/tutorials/dynamically_loaded_filters>` (advanced compression filters)
- API: :class:`types.untyped.DataPipe`

External references
-------------------

- HDF5 background: `Chunking <https://support.hdfgroup.org/documentation/hdf5/latest/hdf5_chunking.html>`_ & `Compression <https://support.hdfgroup.org/documentation/hdf5-docs/hdf5_topics/UsingCompressionInHDF5.html>`_
- Cloud-optimized NetCDF4/HDF5: `Guide <https://guide.cloudnativegeo.org/cloud-optimized-netcdf4-hdf5/>`_
- Cloud-optimized HDF5: `Presentation <https://hdfeos.org/workshops/ws25/presentations/axj.pdf>`_