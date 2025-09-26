.. _hdf5-considerations:

HDF5 Considerations and Limitations
===================================

Working with NWB files in MATLAB involves interacting with the **HDF5** storage format.  
HDF5 provides excellent performance, hierarchical organization, and portability — but it also imposes some important **limitations** that influence how you create, modify, and manage NWB files.  
This page explains these limitations conceptually, so you can design data pipelines and workflows that avoid common pitfalls.

Why limitations matter
----------------------

HDF5 is designed for efficient, large-scale data storage — not for frequent editing or multi-user collaboration.  
Once data is written, changing the file structure or contents is often constrained by the format itself.

Understanding these constraints will help you:

- Plan ahead when designing datasets and attributes
- Avoid costly re-writes and data corruption
- Structure workflows for safe and efficient data access

Key limitations in practice
---------------------------

Existing datasets cannot be freely modified
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Once a dataset is written to disk, it is essentially fixed in size and structure.  
If you need to **append** or **stream** additional data (for example, writing trial data as it becomes available), you must create the dataset with this in mind from the start.

In MatNWB, this is typically done with the :class:`~types.untyped.DataPipe` class, which supports writing data incrementally to an extendable dataset.

Data and attributes cannot be removed — and deletion does not reduce file size
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

HDF5 does not support in-place removal of datasets or attributes in the way a database might.  
While it is possible at a low level to "unlink" objects from the file, this often does not reduce the size of the file.
If you need to significantly restructure a file, the standard approach is to **create a new NWB file** and copy the desired data into it.

**Implication:**  
Plan carefully which datasets and metadata to include before writing. Making changes later often means recreating the file from scratch.


Takeaway
--------

These limitations reflect HDF5’s design priorities: efficient, large-scale storage and high-performance sequential access — **not** dynamic modification or multi-writer concurrency.

When working with NWB in MatNWB, it is therefore important to: design file structure in advance, write data in predictable ways, and treat files as *immutable records* rather than *editable databases*.
