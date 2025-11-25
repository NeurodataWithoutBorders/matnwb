.. _storage-backends:

Storage Backends
================

MatNWB currently uses the HDF5 file format for storing NWB files on disk. Please note that NWB is designed to be storage backend agnostic, and future versions of MatNWB may support additional storage backends.

.. TIP::
   For more information about NWB storage, see the `NWB Storage Documentation <https://nwb-storage.readthedocs.io/en/latest/index.html>`_.

.. _about-hdf5:

What is HDF5?
-------------

HDF5 (Hierarchical Data Format version 5) is a widely used file format for storing large and complex datasets. It is designed to efficiently manage large amounts of heterogeneous data and metadata in a hierarchical structure, making it well-suited for scientific data. It primarily consists of two main components: groups and datasets. Groups are similar to directories in a file system and can contain other groups or datasets. Datasets are multidimensional arrays that hold the actual data. Additionally, both groups and datasets can have attributes, which are small pieces of metadata that provide additional information about the object.

It is especially well suited for NWB files because:

- **Hierarchical organization**: HDF5 files can contain nested groups and datasets, allowing NWB to represent complex relationships between different types of data in a structured way.
- **Efficient storage**: HDF5 supports compression and chunking, which helps reduce file size and improve I/O performance for large datasets.
- **Portability**: HDF5 files can be read and written across different platforms and programming languages, facilitating data sharing and collaboration.
- **Extensibility**: HDF5 allows for the addition of custom metadata and data types, which is important for the evolving needs of neuroscience data.

More details about HDF5 can be found in the `HDF5 Documentation <https://support.hdfgroup.org/documentation/hdf5/latest/index.html>`_.
