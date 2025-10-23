.. _edit-nwb-files:

Editing NWB files
=================

After an NWB file has been exported to disk, it can be re-imported and edited. MatNWB supports **adding new data and metadata** to existing files, as well as **appending to extendable datasets**. This section provides guidance on working with existing NWB files in MatNWB and outlines current limitations.

What MatNWB supports
--------------------

Adding new data to existing files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
MatNWB makes it straightforward to add new data and metadata to existing NWB files. Simply read the file, add your new content, and export it again. For example, you can add new time series, processing modules, or other neurodata objects to an existing file.

Appending data to extendable datasets
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
You can append data to datasets that were created as extendable. :ref:`HDF5 <about-hdf5>` datasets can be created with fixed dimensions or as extendable datasets. To make a dataset extendable, use the :class:`~types.untyped.DataPipe` class when initially creating the dataset, specifying the ``chunkSize`` and ``maxSize`` properties.

The ``maxSize`` property determines the maximum size of the dataset. If you know the final size, set ``maxSize`` to optimize storage. For unlimited growth, set ``maxSize`` to ``Inf`` along one or more dimensions.

For a detailed example of creating and using extendable datasets, see the :doc:`DataPipe tutorial </pages/tutorials/dataPipe>`.


Known limitations in MatNWB
----------------------------

Some editing operations are not currently supported in MatNWB:

**Editing data in-place**
    Modifying existing dataset values after they have been written to disk is not currently supported. If you need to edit data values, you will need to create a new file and write corrected data. 
    
    See `MatNWB Issue #760 <https://github.com/NeurodataWithoutBorders/matnwb/issues/760>`_ for discussion about this feature.

**Appending to non-extendable datasets**
    Datasets created without the :class:`~types.untyped.DataPipe` class have fixed dimensions and cannot be resized. Plan ahead by making datasets extendable if you anticipate needing to append data.

**Removing data to reclaim disk space**
    Due to :ref:`HDF5 <about-hdf5>` limitations, removing datasets or attributes does not reclaim storage space. If you need to significantly restructure a file, create a new NWB file and copy the desired data into it.

    See `MatNWB Issue #751 <https://github.com/NeurodataWithoutBorders/matnwb/issues/751>`_ for progress on this feature.

.. warning::
    The :class:`types.untyped.Set` class provides a ``remove`` method, but this only removes objects from the in-memory representation—it does not remove them from the file on disk or reclaim storage space.

Alternative: PyNWB for advanced editing
----------------------------------------

If you need more advanced editing capabilities that are not currently supported in MatNWB, consider using `PyNWB <https://pynwb.readthedocs.io/en/latest/tutorials/advanced_io/plot_editing.html>`_, which provides:

- Editing dataset values and attributes in-place
- Renaming and moving groups and datasets

Files edited with PyNWB can be read back into MatNWB for further analysis. See the `PyNWB editing tutorial <https://pynwb.readthedocs.io/en/latest/tutorials/advanced_io/plot_editing.html>`_ for detailed examples.

