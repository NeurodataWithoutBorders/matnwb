Performance Optimization
========================

Creating efficient NWB files requires consideration of data layout, compression, and memory usage.  
This page gives conceptual guidance on *why* these factors matter in MatNWB.  
For step-by-step usage, see the :doc:`DataPipe tutorial </pages/tutorials/dataPipe>` and the dynamically loaded filter example (:doc:`dynamically loaded filters </pages/tutorials/dynamically_loaded_filters>`).

Why performance considerations matter
-------------------------------------

NWB files are often used to store large-scale experimental data — from multi-channel electrophysiology to high-resolution imaging.  
Write and read of large datasets can become a bottleneck if dataset layout, storage strategy, or memory handling is not planned up front.

By understanding how HDF5 stores data and how MatNWB interfaces with it, you can:

- Reduce file size without losing precision
- Improve sustained write rates for streaming acquisitions
- Enable analysis on datasets larger than available RAM

Understanding ``DataPipe``
--------------------------

The :class:`types.untyped.DataPipe` class is central to efficient data handling in MatNWB.  
Instead of creating a full MATLAB array before writing, ``DataPipe`` defines *deferred* dataset creation plus incremental population.  
Conceptually, it lets you describe: (1) anticipated shape/growth, (2) storage layout (chunking, compression), and (3) how data will arrive over time.

This enables several key performance optimizations:

Compression
~~~~~~~~~~~

HDF5 supports transparent compression of chunked datasets.  
When enabled via ``DataPipe`` (e.g., specifying a compression filter), file size can be significantly reduced for structured or slowly varying signals.

**When to use:**  
Continuous signals, image stacks, tables with repeated values.  
Avoid (or benchmark) for very small, latency-sensitive random-access datasets.

**MatNWB note:**  
Custom or dynamically loaded filters (e.g., BLOSC, LZ4) can be configured when the underlying HDF5 build supports them—see the :doc:`dynamically loaded filters </pages/tutorials/dynamically_loaded_filters>` tutorial.

Chunking
~~~~~~~~

Chunking divides a dataset into fixed-size blocks on disk.  
Compression, extensibility, and efficient partial I/O all depend on suitable chunking.

**Why it matters:**  
Align chunk dimensions with *typical access slices*: time windows, frame ranges, trial segments, or columnar table growth.  
Poorly chosen chunks can inflate I/O (reading entire oversized chunks) or degrade compression ratios.

**MatNWB note:**  
``DataPipe`` lets you declare chunk sizes up front; you do not later “fix” chunking without rewriting the dataset.

Pre-allocation
~~~~~~~~~~~~~~

If you know (or can bound) the eventual dataset size, pre-allocation (declaring a maximum shape) reduces metadata updates and fragmentation.

**Best practice:**  
Specify a maximum when growth is monotonic and bounded (e.g., number of samples = sampling_rate * duration, frames in an imaging session, expected trial count).

Iterative writing
~~~~~~~~~~~~~~~~~

For datasets exceeding RAM, ``DataPipe`` supports appending or writing slices progressively—processing each batch then discarding it from memory.

**Typical use cases:**

- Streaming continuous ephys directly from an acquisition loop
- Writing large image volumes frame-or-plane at a time
- Building a behavioral table row-wise as trials complete

**MatNWB note:**  
Design the *append axis* early. Changing growth direction after data are written is not supported without copying.

Designing for performance
-------------------------

Optimization is chiefly about aligning *storage* with *anticipated access*:

- Define dataset axes, growth pattern, and approximate bounds before writing.
- Select chunk shapes that mirror dominant retrieval patterns (e.g., (time, channel) vs (frame_y, frame_x)).
- Use compression intentionally—benchmark representative subsets; do not assume the default filter is optimal.
- Stream / append rather than assembling massive in-memory arrays.
- Treat ``DataPipe`` declarations (chunking, compression, max shape) as part of the experimental data model, not an afterthought.

Additional MatNWB considerations
--------------------------------

- MATLAB memory layout (column-major) can influence which axis you stream most cheaply; consider this when choosing chunk dimension ordering.
- Random small writes into highly compressed, large chunks can incur read-modify-write overhead; batch contiguous writes when possible.
- Profiling: Start with a small representative slice (minutes of data, tens of frames) to measure throughput and compression ratio before full-scale export.

Takeaway
--------

Performance optimization in NWB is about aligning data storage with data usage.  
By leveraging ``DataPipe`` features — compression, chunking, pre-allocation, and iterative writing — you can create NWB files that are smaller, faster, and more scalable, even when datasets exceed available RAM.

Related tutorials & references
------------------------------

- Tutorial: :doc:`DataPipe <pages/tutorials/dataPipe>` (practical usage patterns)
- Tutorial: :doc:`dynamically loaded filters <pages/tutorials/dynamically_loaded_filters>` (advanced compression filters)
- API: :class:`types.untyped.DataPipe`
- HDF5 background (external): `Chunking <https://support.hdfgroup.org/documentation/hdf5/latest/hdf5_chunking.html>`_ & `Compression <https://support.hdfgroup.org/documentation/hdf5/latest/_l_b_com_dset.html>`_
