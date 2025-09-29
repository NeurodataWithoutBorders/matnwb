.. _edit-nwb-files:

# Editing NWB files
===================

After an NWB-file has been exported to disk, it can be re-imported and edited. Generally, adding new data and metadata is straightforward. However, due to the way MatNWB and HDF5 work, there are some limitations if modifying or removing datasets from an existing NWB file. This section outlines these limitations and provides guidance on how to work with existing NWB files in MatNWB.

1. Appending data to a dataset requires the dataset to have been created as extendable. This is typically done using the :class:`~types.untyped.DataPipe` class when initially creating the dataset. If the dataset was not created as extendable, it cannot be resized or appended to.

2. Removing property values or neurodata objects from the file object does not free up space in the file itself. If you need to significantly restructure a file, the standard approach is to create a new NWB file and copy the desired data into it.

Appending data to existing datasets
-----------------------------------
:ref:`HDF5 <about-hdf5>` datasets can be created with fixed dimensions or as extendable datasets. By default, MatNWB creates datasets with fixed dimensions. Datasets that were created with fixed dimensions cannot be resized or appended to after they have been written to disk. This means that if you want to append data to a dataset in an existing NWB file, the dataset must have been created as extendable from the start. This is done using the :class:`~types.untyped.DataPipe` class when initially creating the dataset.

The :class:`~types.untyped.DataPipe` class provides a way to create extendable datasets by specifying the `chunkSize` and `maxSize` properties. The `chunkSize` property determines the size of the chunks that will be written to the dataset, while the `maxSize` property determines the maximum size of the dataset. By setting these properties appropriately, you can create a dataset that can be resized and appended to as needed.

If you know the final size of a dataset, `maxSize` can be set to this value to optimize storage allocation. If the final size is unknown, the `maxSize` can be set to `Inf` along one or more dimensions to allow unlimited growth. 

For an example of how to use the :class:`~types.untyped.DataPipe` class to create an extendable dataset, see the :doc:`DataPipe example </pages/tutorials/dataPipe>` tutorial.

Removing data from existing files
---------------------------------
:ref:`HDF5 <about-hdf5>` support for removing datasets or attributes is limited. While it is possible at a low level to "unlink" objects from the file, this does not reclaim the storage space used by that object. If you need to significantly restructure a file, the standard approach is to create a new NWB file and copy the desired data into it.

.. warning::
    The :class:`types.untyped.Set` provides a method called `remove` that can be used to remove objects from a set. However, this only removes the object from the in-memory representation of the file and does not remove it from the file on disk.


At the moment, MatNWB does not provide built-in functionality to copy data from one NWB file to another. However, you can achieve this by manually reading the desired data from the existing file and writing it to a new file using the appropriate MatNWB classes and methods.

The following issue on GitHub tracks some of the limitations and potential improvements related to editing NWB files in MatNWB:
`MatNWB - Issue 751 <https://github.com/NeurodataWithoutBorders/matnwb/issues/751>`_
