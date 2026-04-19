.. _dynamic_tables-tutorial:

Using Dynamic Tables in MatNWB
==============================

.. image:: https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg
   :target: https://matlab.mathworks.com/open/github/v1?repo=NeurodataWithoutBorders/matnwb&file=tutorials/dynamic_tables.mlx
   :alt: Open in MATLAB Online
.. image:: https://img.shields.io/badge/View-Rendered_Live_Script-blue
   :target: ../../_static/html/tutorials/dynamic_tables.html
   :alt: View rendered Live Script


.. contents:: On this page
   :local:
   :depth: 2

This is a user guide to interacting with `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ objects in MatNWB.

**MatNWB setup**
----------------

Start by setting up your MATLAB workspace. The code below adds the directory containing the MatNWB package to the MATLAB search path. MatNWB works by automatically creating API classes based on a defined schema.

.. code-block:: matlab

   %{
   path_to_matnwb = '~/Repositories/matnwb'; % change to your own path location
   addpath(genpath(pwd));
   %}

Constructing a table with initialized columns
---------------------------------------------

The `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ class represents a column-based table to which you can add custom columns. It consists of a description, a list of columns , and a list of row IDs. You can create a `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ by first defining the `VectorData <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/VectorData.html>`_ objects that will make up the columns of the table. Each `VectorData <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/VectorData.html>`_ object must contain the same number of rows. A list of rows IDs may be passed to the `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ using the id argument. Row IDs are a useful way to access row information independent of row location index. The list of row IDs must be cast as an `ElementIdentifiers <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/ElementIdentifiers.html>`_ object before being passed to the `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ object. If no value is passed to id, an `ElementIdentifiers <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/ElementIdentifiers.html>`_ object with 0-indexed row IDs will be created for you automatically.

**MATLAB Syntax Note**: Using column vectors is crucial to properly build vectors and tables. When defining individual values, make sure to use semi-colon (;) instead of instead of comma (,) when defining the data fields of these.

.. code-block:: matlab

   col1 = types.hdmf_common.VectorData( ...
       'description', 'column #1', ...
       'data', [1;2] ...
   );
   
   col2 = types.hdmf_common.VectorData( ...
       'description', 'column #2', ...
       'data', {'a';'b'} ...
   );
   
   row_ids = types.hdmf_common.ElementIdentifiers(...
       'data', [0;1]); % 0-indexed, for compatibility with Python
   
   my_table = types.hdmf_common.DynamicTable( ...
       'description', 'an example table', ...
       'colnames', {'col1', 'col2'}, ...
       'col1', col1, ...
       'col2', col2, ...
       'id', row_ids ...
   );
   my_table

.. code-block:: text

   my_table = 
     DynamicTable with properties:
   
          colnames: {'col1'  'col2'}
       description: 'an example table'
                id: [1x1 types.hdmf_common.ElementIdentifiers]
        vectordata: [2x1 types.untyped.Set]

Adding rows
-----------

You can add rows to an existing `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ using the object's ``addRow`` method. One way of using this method is to pass in the names of columns as parameter names followed by the elements to append. The class of the elements of the column must match the elements to append.

.. code-block:: matlab

   my_table.addRow('col1', 3, 'col2', {'c'}, 'id', 2);

Adding columns
--------------

You can add new columns to an existing `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ object using the ``addColumn`` method. One way of using this method is to pass in the names of each new column followed by the corresponding values for each new column. The height of the new columns must match the height of the table.

.. code-block:: matlab

   col3 = types.hdmf_common.VectorData('description', 'column #3', ...
       'data', [100; 200; 300]);
   col4 = types.hdmf_common.VectorData('description', 'column #4', ...
       'data', {'a1'; 'b2'; 'c3'});
   
   my_table.addColumn('col3', col3,'col4', col4);

Create MATLAB table and convert to dynamic table
------------------------------------------------

As an alternative to building a dynamic table using the `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ and `VectorData <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/VectorData.html>`_ data types, it is also possible to create a MATLAB table and convert it to a dynamic table. Lets create the same table as before, but using MATLAB's table class:

.. code-block:: matlab

   % Create a table with two variables (columns):
   T = table([1;2], {'a';'b'}, 'VariableNames', {'col1', 'col2'});
   T.Properties.VariableDescriptions = {'column #1', 'column #2'};

Adding rows
~~~~~~~~~~~

.. code-block:: matlab

   T(end+1, :) = {3, 'c'};

Adding variables (columns)
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: matlab

   T = addvars(T, [100;200;300], 'NewVariableNames',{'col3'});
   T.Properties.VariableDescriptions{3} = 'column #3';
   
   % Alternatively, a new variable can be added directly using dot syntax.
   T.col4 = {'a1'; 'b2'; 'c3'};
   T.Properties.VariableDescriptions{4} = 'column #4';
   T

.. list-table::
   :header-rows: 1

   * - 
     - col1
     - col2
     - col3
     - col4
   * - 1
     - 1
     - 'a'
     - 100
     - 'a1'
   * - 2
     - 2
     - 'b'
     - 200
     - 'b2'
   * - 3
     - 3
     - 'c'
     - 300
     - 'c3'

Convert to dynamic table
~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: matlab

   dynamic_table = util.table2nwb(T, 'A MATLAB table that was converted to a dynamic table')

.. code-block:: text

   dynamic_table = 
     DynamicTable with properties:
   
          colnames: {'col1'  'col2'  'col3'  'col4'}
       description: "A MATLAB table that was converted to a dynamic table"
                id: [1x1 types.hdmf_common.ElementIdentifiers]
        vectordata: [4x1 types.untyped.Set]

Enumerated (categorical) data
-----------------------------

`EnumData <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_experimental/EnumData.html>`_ is a special type of column for storing an enumerated data type. This way each unique value is stored once, and the data references those values by index. Using this method is more efficient than storing a single value many times, and has the advantage of communicating to downstream tools that the data is categorical in nature.

Warning regarding EnumData
~~~~~~~~~~~~~~~~~~~~~~~~~~

`EnumData <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_experimental/EnumData.html>`_ is currently an experimental feature and as such should not be used in a production environment.

.. code-block:: matlab

   cell_type_elements = types.hdmf_common.VectorData(...
       'description', 'fixed set of elements referenced by cell_type', ...
       'data', {'aa', 'bb', 'cc'} ... % the enumerated elements
   );
   cell_type = types.hdmf_experimental.EnumData( ...
       'description', 'this column holds categorical variables', ...
       'data', [0; 1; 2; 1; 0], ... % zero-indexed offset to elements.
       'elements', types.untyped.ObjectView(cell_type_elements) ...
   );
   
   cell_type_table = types.hdmf_common.DynamicTable(...
       'description', 'an example table with enum cell types');
   %Please note: the *_elements format is required for compatibility with pynwb:
   cell_type_table.vectordata.set('cell_type_elements', cell_type_elements);
   cell_type_table.addColumn('cell_type', cell_type);

Ragged array columns
--------------------

A table column with a different number of elements for each row is called a "ragged array column." To define a table with a ragged array column, pass both the `VectorData <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/VectorData.html>`_ and the corresponding `VectorIndex <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/VectorIndex.html>`_ as columns of the `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ object. The `VectorData <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/VectorData.html>`_ columns will contain the data values. The `VectorIndex <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/VectorIndex.html>`_ column serves to indicate how to arrange the data across rows. By convention the `VectorIndex <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/VectorIndex.html>`_ object corresponding to a particular column must have have the same name with the addition of the '_index' suffix.

Below, the `VectorIndex <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/VectorIndex.html>`_ values indicate to place the 1st to 3rd (inclusive) elements of the `VectorData <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/VectorData.html>`_ into the first row and 4th element into the second row. The resulting table will have the cell {'1a'; '1b'; '1c'} in the first row and the cell {'2a'} in the second row.

.. code-block:: matlab

   col1 = types.hdmf_common.VectorData( ...
       'description', 'column #1', ...
       'data', {'1a'; '1b'; '1c'; '2a'} ...
   );
   
   col1_index = types.hdmf_common.VectorIndex( ...
       'description', 'column #1 index', ...
       'target',types.untyped.ObjectView(col1), ...  % object view of target column
       'data', [3; 4] ...
   );
   
   row_ids = types.hdmf_common.ElementIdentifiers(...
       'data', [0; 1]);  % 0-indexed, for compatibility with Python
   
   table_ragged_col = types.hdmf_common.DynamicTable( ...
       'description', 'an example table', ...
       'colnames', {'col1'}, ...
       'col1', col1, ...
       'col1_index', col1_index, ...
       'id', row_ids ...
   );

Adding ragged array rows
~~~~~~~~~~~~~~~~~~~~~~~~

You can add a new row to the ragged array column. Under the hood, the ``addRow`` method will add the appropriate value to the `VectorIndex <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/VectorIndex.html>`_ column to maintain proper formatting.

.. code-block:: matlab

   table_ragged_col.addRow('col1', {'3a'; '3b'; '3c'}, 'id', 2);

Accessing row elements
----------------------

You can access data from entire rows of a `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ object by calling the ``getRow`` method for the corresponding object. You can supply either an individual row number or a list of row numbers.

.. code-block:: matlab

   my_table.getRow(1)

.. list-table::
   :header-rows: 1

   * - 
     - col1
     - col2
     - col3
     - col4
   * - 1
     - 1
     - 'a'
     - 100
     - 'a1'

If you want to access values for just a subset of columns you can pass in the 'columns' argument along with a cell array with the desired column names

.. code-block:: matlab

   my_table.getRow(1:3, 'columns', {'col1'})

.. list-table::
   :header-rows: 1

   * - 
     - col1
   * - 1
     - 1
   * - 2
     - 2
   * - 3
     - 3

You can also access specific rows by their corresponding row ID's, if they have been defined, by supplying a 'true' Boolean to the 'useId' parameter

.. code-block:: matlab

   my_table.getRow(1, 'useId', true)

.. list-table::
   :header-rows: 1

   * - 
     - col1
     - col2
     - col3
     - col4
   * - 1
     - 2
     - 'b'
     - 200
     - 'b2'

For a ragged array columns, the ``getRow`` method will return a cell with different number of elements for each row

.. code-block:: matlab

   table_ragged_col.getRow(1:2)

.. list-table::
   :header-rows: 1

   * - 
     - col1
   * - 1
     - 3x1 cell
   * - 2
     - 1x1 cell

Accessing column elements
-------------------------

To access all rows from a particular column use the .get method on the vectordata field of the `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ object

.. code-block:: matlab

   my_table.vectordata.get('col2').data

.. code-block:: text

   ans = 3x1 cell
   'a'         
   'b'         
   'c'         

Referencing rows of other tables
--------------------------------

You can create a column that references rows of other tables by adding a `DynamicTableRegion <file:///Users/cesar/Repositories/matnwb/doc/+types/+hdmf_common/DynamicTableRegion.html>`_ object as a column of a `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_. This is analogous to a foreign key in a relational database. The `DynamicTableRegion <file:///Users/cesar/Repositories/matnwb/doc/+types/+hdmf_common/DynamicTableRegion.html>`_ class takes in an ``ObjectView`` object as argument. ``ObjectView`` objects create links from one object type referencing another.

.. code-block:: matlab

   dtr_col = types.hdmf_common.DynamicTableRegion( ...
       'description', 'references multiple rows of earlier table', ...
       'data', [0; 1; 1; 0], ...  # 0-indexed
       'table',types.untyped.ObjectView(my_table) ...  % object view of target table
   );
   
   data_col = types.hdmf_common.VectorData( ...
       'description', 'data column', ...
       'data', {'a'; 'b'; 'c'; 'd'} ...
   );
   
   dtr_table = types.hdmf_common.DynamicTable( ...
       'description', 'test table with DynamicTableRegion', ...
       'colnames', {'data_col', 'dtr_col'}, ...
       'dtr_col', dtr_col, ...
       'data_col',data_col, ...
       'id',types.hdmf_common.ElementIdentifiers('data', [0; 1; 2; 3]) ...
   );

Converting a `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ **to a MATLAB table**
------------------------------------------------------------------------------------------------------------------------------------------------

You can convert a `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ object to a MATLAB table by making use of the object's ``toTable`` method. This is a useful way to view the whole table in a human-readable format.

.. code-block:: matlab

   my_table.toTable()

.. list-table::
   :header-rows: 1

   * - 
     - id
     - col1
     - col2
     - col3
     - col4
   * - 1
     - 0
     - 1
     - 'a'
     - 100
     - 'a1'
   * - 2
     - 1
     - 2
     - 'b'
     - 200
     - 'b2'
   * - 3
     - 2
     - 3
     - 'c'
     - 300
     - 'c3'

When the `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ object contains a column that references other tables, you can pass in a Boolean to indicate whether to include just the row indices of the referenced table. Passing in ``false`` will result in inclusion of the referenced rows as nested tables.

.. code-block:: matlab

   dtr_table.toTable(false)

.. list-table::
   :header-rows: 1

   * - 
     - id
     - data_col
     - dtr_col
   * - 1
     - 0
     - 'a'
     - 1x4 table
   * - 2
     - 1
     - 'b'
     - 1x4 table
   * - 3
     - 2
     - 'c'
     - 1x4 table
   * - 4
     - 3
     - 'd'
     - 1x4 table

Creating an expandable table
----------------------------

When using the default HDF5 backend, each column of these tables is an HDF5 Dataset, which by default are set to an unchangeable size. This means that once a file is written, it is not possible to add a new row. If you want to be able to save this file, load it, and add more rows to the table, you will need to set this up when you create the `VectorData <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/VectorData.html>`_ and `ElementIdentifiers <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/ElementIdentifiers.html>`_ columns of a `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_. Specifically, you must wrap the column data with a **DataPipe** object. The **DataPipe** class takes in ``maxSize`` and ``axis`` as arguments to indicate the maximum desired size for each axis and the axis to which to append to, respectively. For example, creating a **DataPipe** object with a *maxSize* value equal to ``[Inf, 1]`` indicates that the number of rows may increase indefinitely. In contrast, setting *maxSize* equal to ``[8, 1]`` would allow the column to grow to a maximum height of 8.

.. code-block:: matlab

   % create NwbFile object with required fields
   file = NwbFile( ...
       'session_start_time', datetime('2021-01-01 00:00:00', 'TimeZone', 'local'), ...
       'identifier', 'ident1', ...
       'session_description', 'ExpandableTableTutorial' ...
   );
   
   % create VectorData objects with DataPipe objects
   start_time_exp = types.hdmf_common.VectorData( ...
       'description', 'start times column', ...
       'data', types.untyped.DataPipe( ...
           'data', [1, 2], ...  # data must be numerical
           'maxSize', Inf ...
       ) ...
   );
   
   stop_time_exp = types.hdmf_common.VectorData( ...
       'description', 'stop times column', ...
       'data', types.untyped.DataPipe( ...
           'data', [2, 3], ...  #data must be numerical
           'maxSize', Inf ...
       ) ...
   );
   
   random_exp = types.hdmf_common.VectorData( ...
       'description', 'random data column', ...
       'data', types.untyped.DataPipe( ...
           'data', rand(5, 2), ...  #data must be numerical
           'maxSize', [5, Inf], ...
           'axis', 2 ...
       ) ...
   );
   
   ids_exp = types.hdmf_common.ElementIdentifiers( ...
       'data', types.untyped.DataPipe( ...
           'data', int32([0; 1]), ...  # data must be numerical
           'maxSize', Inf ...
       ) ...
   );
   % create expandable table
   colnames = {'start_time', 'stop_time', 'randomvalues'};
   file.intervals_trials = types.core.TimeIntervals( ...
       'description', 'test expdandable dynamic table', ...
       'colnames', colnames, ...
       'start_time', start_time_exp, ...
       'stop_time', stop_time_exp, ...
       'randomvalues', random_exp, ...
       'id', ids_exp ...
   );
   % export file
   nwbExport(file, 'expandableTableTestFile.nwb');

Now, you can read in the file, add more rows, and save again to file

.. code-block:: matlab

   read_file = nwbRead('expandableTableTestFile.nwb', 'ignorecache');
   read_file.intervals_trials.addRow( ...
       'start_time', 3, ...
       'stop_time', 4, ...
       'randomvalues', rand(5,1), ...
       'id', 2 ...
       )
   nwbExport(read_file, 'expandableTableTestFile.nwb');

**Note: DataPipe** objects change how the dimension of the datasets for each column map onto the shape of HDF5 datasets. See the `documentation <https://matnwb.readthedocs.io/en/latest/pages/concepts/dimension_ordering.html>`_ for more details.

Multidimensional columns
------------------------

The order of dimensions of multidimensional columns in MatNWB is reversed relative to the Python HDMF package (see `documentation <https://matnwb.readthedocs.io/en/latest/pages/concepts/dimension_ordering.html>`_ for detailed explanation). Therefore, the height of a multidimensional column belonging to a `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ object is defined by the shape of its last dimension. A valid `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ must have matched height across columns.

Constructing multidimensional columns
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: matlab

   % Define 1D column
   simple_col = types.hdmf_common.VectorData( ...
       'description', '1D column',...
       'data', rand(10,1) ...
   );
   % Define ND column
   multi_col = types.hdmf_common.VectorData( ...
       'description', 'multidimensional column',...
       'data', rand(3,2,10) ...
   );
   % construct table
   multi_dim_table = types.hdmf_common.DynamicTable( ...
       'description','test table', ...
       'colnames', {'simple','multi'}, ...
       'simple', simple_col, ...
       'multi', multi_col, ...
       'id', types.hdmf_common.ElementIdentifiers('data', (0:9)') ...
   );

Multidimensional ragged array columns
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

`DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ objects with multidimensional ragged array columns can be constructed by passing in the corresponding `VectorIndex <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/VectorIndex.html>`_ column

.. code-block:: matlab

   % Define column with data
   multi_ragged_col = types.hdmf_common.VectorData( ...
       'description', 'multidimensional ragged array column',...
       'data', rand(2,3,5) ...
   );
   % Define column with VectorIndex
   multi_ragged_index = types.hdmf_common.VectorIndex( ...
       'description', 'index to multi_ragged_col', ...
       'target', types.untyped.ObjectView(multi_ragged_col),'data', [2; 3; 5] ...
   );
   
   multi_ragged_table = types.hdmf_common.DynamicTable( ...
       'description','test table', ...
       'colnames', {'multi_ragged'}, ...
       'multi_ragged', multi_ragged_col, ...
       'multi_ragged_index', multi_ragged_index, ...
       'id', types.hdmf_common.ElementIdentifiers('data', [0; 1; 2]) ...
   );

Adding rows to multidimensional array columns
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

`DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ objects with multidimensional array columns can also be constructed by adding a single row at a time. This method makes use of **DataPipe** objects due to the fact that MATLAB doesn't support singleton dimensions for arrays with more than 2 dimensions. The code block below demonstrates how to build a `DynamicTable <https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/hdmf_common/DynamicTable.html>`_ object with a multidimensional ragged array column in this manner.

.. code-block:: matlab

   % Create file
   file = NwbFile( ...
       'session_start_time', datetime('2021-01-01 00:00:00', 'TimeZone', 'local'), ...
       'identifier', 'ident1', ...
       'session_description', 'test_file' ...
   );
   
   % Define Vector Data Objects with first row of table
   start_time_exp = types.hdmf_common.VectorData( ...
       'description', 'start times column', ...
       'data', types.untyped.DataPipe( ...
           'data', 1, ...
           'maxSize', Inf ...
       ) ...
   );
   stop_time_exp = types.hdmf_common.VectorData( ...
       'description', 'stop times column', ...
       'data', types.untyped.DataPipe( ...
           'data', 10, ...
           'maxSize', Inf ...
       ) ...
   );
   random_exp = types.hdmf_common.VectorData( ...
       'description', 'random data column', ...
       'data', types.untyped.DataPipe( ...
           'data', rand(3,2,5), ...  #random data
           'maxSize', [3, 2, Inf], ...
           'axis', 3 ...
       ) ...
   );
   random_exp_index = types.hdmf_common.VectorIndex( ...
       'description', 'index to random data column', ...
       'target', types.untyped.ObjectView(random_exp), ...
       'data', types.untyped.DataPipe( ...
           'data', uint64(5), ...
           'maxSize', Inf ...
       ) ...
   );
   ids_exp = types.hdmf_common.ElementIdentifiers( ...
       'data', types.untyped.DataPipe( ...
           'data', int64(0), ...  # data must be numerical
           'maxSize', Inf ...
       ) ...
   );
   % Create expandable table
   colnames = {'start_time', 'stop_time', 'randomvalues'};
   file.intervals_trials = types.core.TimeIntervals( ...
       'description', 'test expdandable dynamic table', ...
       'colnames', colnames, ...
       'start_time', start_time_exp, ...
       'stop_time', stop_time_exp, ...
       'randomvalues', random_exp, ...
       'randomvalues_index', random_exp_index, ...
       'id', ids_exp ...
   );
   % Export file
   nwbExport(file, 'multiRaggedExpandableTableTest.nwb');
   % Read in file
   read_file = nwbRead('multiRaggedExpandableTableTest.nwb', 'ignorecache');
   % add individual rows
   read_file.intervals_trials.addRow( ...
       'start_time', 2, ...
       'stop_time', 20, ...
       'randomvalues', rand(3,2,6), ...
       'id', 1 ...
   );
   read_file.intervals_trials.addRow( ...
       'start_time', 3, ...
       'stop_time', 30, ...
       'randomvalues', rand(3,2,3), ...
       'id', 2 ...
   );
   read_file.intervals_trials.addRow( ...
       'start_time', 4, ...
       'stop_time', 40, ...
       'randomvalues', rand(3,2,8), ...
       'id', 3 ...
   );

Learn more!
-----------

Python Tutorial
~~~~~~~~~~~~~~~

`DynamicTable Tutorial <https://hdmf.readthedocs.io/en/stable/tutorials/plot_dynamictable_tutorial.html#sphx-glr-tutorials-plot-dynamictable-tutorial-py>`_
