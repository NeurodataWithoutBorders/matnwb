.. _matnwb-read-untyped-intro:

Utility Types in MatNWB
=======================

.. note::

    API documentation for "untyped" types will be added in the future.

"Untyped" utility types are classes not defined by the NWB schema, but used alongside NWB data classes to provide additional functionality when reading or writing NWB files with MatNWB. These types are located in the ``+types/+untyped/`` namespace within the MatNWB root directory. The following untyped types are described in this section:

.. contents::
   :local:
   :depth: 1

.. _matnwb-read-untyped-sets-anons:

Sets
~~~~

The **Set** class (``types.untyped.Set``) is used to store a dynamic collection of NWB-typed objects.
Some NWB data types may include other data types as property values. The **Set** class supports this by enforcing constraints on its members—for example, restricting the set to contain only specified data types.
For this reason, it is also referred to as a *constrained set*.

Data objects are added to a **Set** as name-value pairs using the ``add`` method:

.. code-block:: MATLAB

    aTimeSeries = types.core.TimeSeries('data', rand(1,10));
    someSet = types.untyped.Set();
    someSet.add('my timeseries', aTimeSeries)

The example above creates a new **Set** with one entry:

.. code-block:: MATLAB

    >> someSet

    someSet = 

      Set with entries:

        myTimeseries: types.core.TimeSeries

The data object (``TimeSeries``) is added as a dynamic property on the **Set** object. Because MATLAB does not support whitespace or special characters in property names, the name is remapped to a valid MATLAB identifier.

.. note::

    The name provided when adding a data object to a **Set** is preserved in the NWB file. Tools like PyNWB or other NWB/HDF5 readers will display this original name—for example, ``'my timeseries'``.  
    **In MatNWB, we recommend using a consistent naming style that is valid in MATLAB (e.g., PascalCase) to avoid naming ambiguities.**

To retrieve the value, refer to the property directly:

.. code-block:: MATLAB

    timeSeriesCopy = someSet.myTimeseries


Supporting legacy syntax
------------------------

MatNWB also supports legacy syntax for setting and retrieving items in a **Set**:

.. code-block:: MATLAB

    value = someSet.get('key name');

.. code-block:: MATLAB

    someSet.set('key name', value);

.. note::

    The **Set** class also supports the ``keys`` and ``values`` methods, similar to ``containers.Map``, for retrieving cell arrays of keys or values.


..
   %% The paragraph describing Anon is commented out because the Anon appears to be unused %%
   The **Anon** type (``types.untyped.Anon``) can be understood as a Set type with only a single key-value entry. This rarer type is only used for cases where the name for the stored object can be set by the user. Anon types may also hold NWB type constraints like Set.

.. _matnwb-read-untyped-datastub-datapipe:

DataStubs and DataPipes
~~~~~~~~~~~~~~~~~~~~~~~

**DataStubs** serves as a read-only link to your data. It allows for MATLAB-style indexing to retrieve the data stored on disk.

.. image:: https://github.com/NeurodataWithoutBorders/nwb-overview/blob/main/docs/source/img/matnwb_datastub.png?raw=true


**DataPipes** are similar to DataStubs in that they allow you to load data from disk; however, they also provide a wide array of features that allow the user to write data to disk, either by streaming parts of data in at a time or by compressing the data before writing. The DataPipe is an advanced type and users looking to leverage DataPipe's capabilities to stream/iteratively write or compress data should read the :doc:`Advanced Data Write Tutorial </pages/tutorials/dataPipe>`


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
