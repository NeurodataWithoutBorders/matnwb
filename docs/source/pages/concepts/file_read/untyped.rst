.. _matnwb-read-untyped-intro:

Utility Types in MatNWB
=======================

.. note::

    Documentation for "untyped" types will be added soon

"Untyped" Utility types are tools which allow for both flexibility as well as limiting certain constraints that are imposed by the NWB schema. These types are commonly stored in the ``+types/+untyped/`` package directories in your MatNWB installation.

.. _matnwb-read-untyped-sets-anons:

Sets and Anons
~~~~~~~~~~~~~~

The **Set** (``types.untyped.Set`` or Constrained Sets) is used to capture a dynamic number of particular NWB-typed objects. They may contain certain type constraints on what types are allowable to be set. Set keys and values can be set and retrieved using their ``set`` and ``get`` methods:

.. code-block:: MATLAB

    value = someSet.get('key name');

.. code-block:: MATLAB

    someSet.set('key name', value);

.. note::

    Sets also borrow ``containers.Map``'s ``keys`` and ``values`` methods to retrieve cell arrays of either.

The **Anon** type (``types.untyped.Anon``) can be understood as a Set type with only a single key-value entry. This rarer type is only used for cases where the name for the stored object can be set by the user. Anon types may also hold NWB type constraints like Set.

.. _matnwb-read-untyped-datastub-datapipe:

DataStubs and DataPipes
~~~~~~~~~~~~~~~~~~~~~~~

When working with NWB files, datasets can be very large (gigabytes or more). Loading all this data into memory at once would be impractical or impossible. MatNWB uses two types to handle on-disk data efficiently: **DataStubs** and **DataPipes**.

DataStubs (Read only)
^^^^^^^^^^^^^^^^^^^^^

A **DataStub** (``types.untyped.DataStub``) represents a read-only reference to data stored in an NWB file. When you read an NWB file, large datasets are automatically represented as DataStubs rather than loaded into memory.

.. image:: https://github.com/NeurodataWithoutBorders/nwb-overview/blob/main/docs/source/img/matnwb_datastub.png?raw=true

Key characteristics:

- **Lazy loading**: Data remains on disk until you explicitly access it
- **Memory efficient**: Only the portions you request are loaded
- **MATLAB-style indexing**: Access data using familiar syntax like ``dataStub(1:100, :)``
- **Read-only**: Cannot be used to modify or write data

You'll encounter DataStubs whenever you read existing NWB files containing non-scalar or multi-dimensional datasets.

DataPipes (read and write)
^^^^^^^^^^^^^^^^^^^^^^^^^^

A **DataPipe** (``types.untyped.DataPipe``) extends the concept of lazy data access to support **writing** as well as reading. While DataStubs are created automatically when reading files, you create DataPipes explicitly when writing data.

Key characteristics:

- **Bidirectional**: Supports both reading and writing operations
- **Incremental writing**: Stream data to disk in chunks rather than all at once
- **Compression support**: Apply HDF5 compression and chunking strategies
- **Write optimization**: Configure how data is stored on disk for better performance

DataPipes solve the problem of writing datasets that are too large to fit in memory, or when you want fine-grained control over how data is stored in the HDF5 file.

.. seealso::

   - For detailed guidance on creating and configuring DataPipes, see :ref:`Advanced Data Write Tutorial </pages/tutorials/dataPipe>`

   .. todo
   - For practical examples of reading data via DataStubs, see :ref:`How to Read Data </pages/how-to/read-on-demand>`

.. _matnwb-read-untyped-links-views:

Links and Views
~~~~~~~~~~~~~~~

**Links** (either ``types.untyped.SoftLink`` or ``types.untyped.ExternalLink``) are views that point to another NWB object, either within the same file or in another external one. *SoftLinks* contain a path into the same NWB file while *ExternalLinks* additionally hold a ``filename`` field to point to an external NWB file. Both types use their ``deref`` methods to retrieve the NWB object that they point to though *SoftLinks* require the NwbFile object that was read in.

.. code-block:: MATLAB

    referencedObject = softLink.deref(rootNwbFile);

.. code-block:: MATLAB

    referencedObject = externalLink.deref();

.. note::

    Links are not validated on write by default. It is entirely possible that a link will simply never resolve, either because the path to the NWB object is wrong, or because the external file is simply missing from the NWB distribution.

**Views** (either ``types.untyped.ObjectView`` or ``types.untyped.RegionView``) are more advanced references which can point to NWB types as well as segments of raw data from a dataset. *ObjectViews* will point to NWB types while *RegionViews* will point to some subset of data. Both types use ``refresh`` to retrieve their referenced data.

.. code-block:: MATLAB

    referencedObject = objectView.refresh(rootNwbFile);

.. code-block:: MATLAB

    dataSubset = regionView.refresh(rootNwbFile);

.. note::

    Unlike *Links*, Views cannot point to NWB objects outside of their respective files. Views are also validated on write and will always point to a valid NWB object or raw data if written without errors.
