.. _matnwb-read-dynamic-table-intro:

The Dynamic Table Type
======================

The :class:`types.hdmf_common.DynamicTable` is a special NWB type composed of multiple ``VectorData`` objects which act like the columns of a table. The benefits of this type composition is that it allows us to add user-defined columns to a ``DynamicTable`` without having extend the NWB data schema and each column can be accessed independently using regular NWB syntax and modified as a regular dataset.

With such an object hierarchy, however, there is no easy way to view the Dynamic Table data row by row. This is where ``getRow`` comes in.

.. _matnwb-read-dynamic-table-row-view:

Row-by-row viewing
~~~~~~~~~~~~~~~~~~

``getRow`` retrieves one or more rows of the dynamic table and produces a MATLAB `table <https://www.mathworks.com/help/matlab/ref/table.html>`_ with a representation of the data. It should be noted that this returned table object is **readonly** and any changes to the returned table will not be reflected back into the NWB file.

By default, you must provide the row index as an argument. This is 1-indexed and follows MATLAB indexing behavior.

.. code-block:: MATLAB

    tableData = dynamicTable.getRow(<tableIndex>);

You can also filter your view by specifying what columns you wish to see.

.. code-block:: MATLAB
    
    filteredData = dynamicTable.getRow(<tableIndex>, 'columns', {'columnName'});

In the above example, the ``filteredData`` table will only have the "columnName" column data loaded.

Finally, if you prefer to select using your custom ``id`` column, you can specify by setting the ``useId`` keyword.

.. code-block:: MATLAB

    tableData = dynamicTable.getRow(<idValue>, 'useId', true);

For more information regarding Dynamic Tables in MatNWB as well as information regarding writing data to them, please see the `MatNWB DynamicTables Tutorial <../../tutorials/dynamic_tables.html>`_.
