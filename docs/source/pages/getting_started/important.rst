Important
=========

When using MatNWB, it is important to understand the differences in how array 
dimensions are ordered in MATLAB versus HDF5. While the NWB documentation and 
tutorials generally follow the NWB Schema Specifications, MatNWB requires data 
to be added with dimensions in reverse order.

For example, in the NWB Schema, the time dimension is specified as the first 
dimension of a dataset. However, in MatNWB, the time dimension should always 
be added as the last dimension.

Data Dimensions
---------------

Dimension Ordering
^^^^^^^^^^^^^^^^^^

NWB files use the HDF5 format to store data. There are two main differences 
between the way MATLAB and HDF5 represents dimensions. The first is that HDF5 
is C-ordered, which means it stores data is a rows-first pattern, and the 
MATLAB is F-ordered, storing data in the reverse pattern, with the last 
dimension of the array stored consecutively. The result is that the data in 
HDF5 is effectively the transpose of the array in MATLAB. The second difference 
is that HDF5 can store 1-D arrays, but in MATLAB the lowest dimensionality of 
an array is 2-D. Due to differences in how MATLAB and HDF5 represent data, the 
dimensions of datasets are flipped when writing to/from file in MatNWB. This 
behavior differs depending on whether :class:`types.hdmf_common.VectorData` 
use ``DataPipe`` objects to contain the data. It's important to keep in mind 
the mappings below to make sure is written to and read from file as expected.

Without DataPipes
^^^^^^^^^^^^^^^^^

See the documentation at the following link: 
`without DataPipes <../tutorials/dimensionMapNoDataPipes.html>`_

**Writing to File**

.. list-table::
   :header-rows: 1

   * - Shape in MatNWB
     - Shape in HDF5
   * - (M, 1)
     - (M,)
   * - (1, M)
     - (M,)
   * - (P, O, N, M)
     - (M, N, O, P)

**Reading from File**

.. list-table::
   :header-rows: 1

   * - Shape in HDF5
     - Shape in MatNWB
   * - (M,)
     - (M, 1)
   * - (M, N, O, P)
     - (P, O, N, M)

.. note::

   MATLAB does not support 1D datasets. HDF5 datasets of size (M,) are loaded into MATLAB as datasets of size (M,1). To avoid changes in dimensions when writing to/from file, use column vectors for 1D datasets.

With DataPipes
^^^^^^^^^^^^^^

See the documentation at the following link: 
`with DataPipes <../tutorials/dimensionMapWithDataPipes.html>`_

**Writing to File**

.. list-table::
   :header-rows: 1

   * - Shape in MatNWB
     - Shape in HDF5
   * - (M, 1)
     - (1, M)
   * - (1, M)
     - (M, 1) / (M,) **
   * - (P, O, N, M)
     - (M, N, O, P)

\*\* Use scalar as input to ``maxSize`` argument to write a dataset of shape (N,)

**Reading from File**

.. list-table::
   :header-rows: 1

   * - Shape in HDF5
     - Shape in MatNWB
   * - (M, 1)
     - (1, M)
   * - (1, M)
     - (M, 1)
   * - (M,)
     - (M, 1)
   * - (M, N, O, P)
     - (P, O, N, M)
