Performance Optimization
========================

Creating efficient NWB files requires consideration of data layout, compression, and memory usage.  
This page explains the key factors that influence performance when writing large datasets with MatNWB and how to design your workflows to make the most of them.

Why performance considerations matter
-------------------------------------

NWB files are often used to store large-scale experimental data — from multi-channel electrophysiology to high-resolution imaging.  
Writing and reading such datasets can quickly become a bottleneck if the file layout, storage strategy, or memory handling is not carefully planned.

By understanding how HDF5 stores data and how MatNWB interfaces with it, you can:

- Reduce file size without losing precision
- Speed up read and write operations
- Work efficiently with datasets larger than your available RAM

Understanding ``DataPipe``
--------------------------

The :class:`~types.untyped.DataPipe` class is central to efficient data handling in MatNWB.  
Rather than writing a complete dataset in one step, ``DataPipe`` allows you to define how data should be stored *and* written over time.  
This enables several key performance optimizations:

Compression
~~~~~~~~~~~

HDF5 supports transparent compression of datasets.  
When enabled via ``DataPipe``, compression can reduce file size significantly — often by an order of magnitude — without changing how you read or write the data later.

**When to use:**  
Compression is most beneficial for continuous or image-like data with redundant structure.  
For small datasets or those requiring ultra-fast random access, compression may add overhead.

Chunking
~~~~~~~~

Chunking divides a dataset into fixed-size blocks (chunks) on disk.  
This improves performance when reading or writing subsets of data and is essential when using compression.

**Why it matters:**  
Choosing a chunk size that matches your typical access pattern — for example, time windows, frames, or trials — ensures that reads and writes align with how the data is stored, avoiding unnecessary I/O.

Pre-allocation
~~~~~~~~~~~~~~

If you know the approximate size of a dataset in advance, pre-allocating space can improve write performance and prevent fragmentation.  
``DataPipe`` allows you to specify an expected maximum shape, so the file can reserve sufficient space before data is written.

**Best practice:**  
Use pre-allocation when datasets will grow over time but the total size is bounded (e.g. adding trials sequentially).

Iterative writing
~~~~~~~~~~~~~~~~~

For datasets that exceed available RAM, ``DataPipe`` supports writing data incrementally.  
This means you can process and write data in chunks — for example, frame by frame or batch by batch — without ever loading the entire dataset into memory.

**Typical use cases:**

- Writing continuous recordings as they stream from acquisition hardware
- Processing and storing image stacks larger than system memory
- Incrementally populating a large behavioral table

Designing for performance
-------------------------

Optimizing NWB performance is less about tweaking individual parameters and more about designing the **data flow** with these principles in mind:

- Plan dataset shapes and sizes before writing.
- Use compression and chunking deliberately, based on how the data will be accessed.
- Write incrementally rather than assembling massive arrays in memory.
- Treat ``DataPipe`` as part of the design, not just a convenience.

Takeaway
--------

Performance optimization in NWB is about aligning data storage with data usage.  
By leveraging ``DataPipe`` features — compression, chunking, pre-allocation, and iterative writing — you can build NWB files that are smaller, faster, and more scalable, even when working with datasets far larger than available RAM.
