.. _how_to_working_with_containers:

Working with Container Properties and Types
===========================================

This guide shows you how to work with NWB properties and types that is designed to hold other data objects (containers).

.. contents::
   :local:
   :depth: 2

Overview
--------
Some neurodata types and properties of neurodata types in NWB are designed to hold one or more data objects of specific types. We will refer to these neurodata types and properties as "containers". For example, both the ``acquisition`` property of a :class:`types.core.NWBFile` and the :class:`types.core.ProcessingModule` neurodata type can contain multiple data objects of :class:`types.core.NWBDataInterface` or :class:`types.hdmf_common.DynamicTable` types (including subtypes). A container is represented internally using the :class:`types.untyped.Set` and MatNWB provides convenient syntax that mimics standard MATLAB property access for working with these containers.

**Adding data objects:**

.. code-block:: MATLAB

    % Use the add() method
    container.add('MyTimeSeries', timeSeriesObject);

**Retrieving data objects:**

.. code-block:: MATLAB

    % Use dot-indexing like any MATLAB property
    timeSeries = container.MyTimeSeries;

Adding Data Objects
-------------------

Using the add() method
~~~~~~~~~~~~~~~~~~~~~~

The ``add()`` method is the recommended way to add data objects to containers:

.. code-block:: MATLAB

    % Create a processing module
    processingModule = types.core.ProcessingModule('description', 'My processing module');
    
    % Create some data objects
    timeSeries = types.core.TimeSeries( ...
        'data', rand(100, 1), ...
        'data_unit', 'volts', ...
        'timestamps', linspace(0, 1, 100));
    
    dataTable = types.hdmf_common.DynamicTable( ...
        'description', 'My data table');
    
    % Add them to the module
    processingModule.add('NeuralActivity', timeSeries);
    processingModule.add('DataTable', dataTable);

During construction
~~~~~~~~~~~~~~~~~~~

You can also add data objects when creating the container:

.. code-block:: MATLAB

    processingModule = types.core.ProcessingModule( ...
        'description', 'My processing module', ...
        'NeuralActivity', timeSeries, ...
        'DataTable', dataTable);

Accessing Data Objects
-----------------------

Direct property access
~~~~~~~~~~~~~~~~~~~~~~

Once added, data objects are accessible as properties of the container:

.. code-block:: MATLAB

    % Retrieve by property name
    timeSeries = processingModule.NeuralActivity;
    dataTable = processingModule.DataTable;
    
    % You can then access their properties
    data = timeSeries.data;
    timestamps = timeSeries.timestamps;

This works exactly like accessing any other MATLAB object property.

Checking if an object exists
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use ``isprop()`` to check if a data object exists:

.. code-block:: MATLAB

    if isprop(processingModule, 'NeuralActivity')
        timeSeries = processingModule.NeuralActivity;
    end

This approach helps avoid errors when trying to access non-existent objects.

Removing Data Objects
----------------------

Use the ``remove()`` method to remove data objects:

.. code-block:: MATLAB

    % Remove a data object by its name
    processingModule.remove('NeuralActivity');
    
    % Verify it's gone
    hasProperty = isprop(processingModule, 'NeuralActivity');  % Returns false

.. note::

    The ``remove()`` method only removes objects from memory. It does not remove neurodata objects from files that have been read from disk. To modify the contents of an existing NWB file, you need to create a new file with the desired changes.

Working with Names
------------------

Handling invalid MATLAB names
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

MATLAB property names must follow specific rules (no spaces, special characters, must start with a letter, etc.). When you add a data object with a name that isn't a valid MATLAB identifier, MatNWB automatically creates a valid alias:

.. code-block:: MATLAB

    % Add with spaces and special characters
    processingModule.add('my time series', timeSeries);
    processingModule.add('Data-Table', dataTable);
    
    % Access using valid MATLAB identifiers
    timeSeries = processingModule.myTimeSeries;     % Spaces removed, camelCase
    dataTable = processingModule.Data_Table;        % Hyphen replaced with underscore

.. important::

    The **original name** is preserved in the NWB file. Other tools (like PyNWB) will see ``'my time series'`` and ``'Data-Table'``, not the MATLAB aliases.

.. tip::

    **Best practice:** Use names that are valid MATLAB identifiers from the start (e.g., PascalCase, camelCase or snake_case) to avoid confusion:
    
    .. code-block:: MATLAB
    
        processingModule.add('MyTimeSeries', timeSeries);
        processingModule.add('myTimeSeries', timeSeries);
        processingModule.add('my_time_series', timeSeries);

If you read files created by other tools with names that are not valid MATLAB identifiers, MatNWB will automatically create appropriate aliases when loading the data.

Viewing name mappings (aliases)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If MatNWB creates aliases, a warning will display showing the mapping between original names and property names when the container type is displayed in MATLAB's command window. 

.. code-block:: MATLAB

    % Create a processing module
    processingModule = types.core.ProcessingModule('description', 'My processing module');
    
    % Add with spaces and special characters
    processingModule.add('my time series', timeSeries);
    processingModule.add('data-table', dataTable);
    disp(processingModule)

**Output:**

.. code-block:: MATLAB

    Warning: Names for some entries of "ProcessingModule" have been modified to make them valid 
    MATLAB identifiers (the original names will still be used when data is exported to file):

        ValidIdentifier      OriginalName
        _______________    ________________

        "myTimeSeries"     "my time series"
        "data_table"       "data-table"
    
    ProcessingModule with properties:

        description: 'My analysis module'
        myTimeSeries: [1×1 types.core.TimeSeries]
        data_table: [1×1 types.hdmf_common.DynamicTable]

You can also use the ``getAliasMap()`` method to retrieve a table showing the name mappings programmatically:

.. code-block:: MATLAB

    nameMap = processingModule.getAliasMap()

**Output:**

.. code-block:: MATLAB

    nameMap =

    2×2 table

        ValidIdentifier      OriginalName  
        _______________    ________________

        "myTimeSeries"     "my time series"
        "data_table"       "data-table" 

.. note::

    In addition to using alias names for property access, you can also use legacy ``.get()`` and ``.set()`` methods on the underlying ``types.untyped.Set`` objects if needed (see Advanced Topics below).

Troubleshooting
---------------

Property name conflicts
~~~~~~~~~~~~~~~~~~~~~~~

If you try to add an object with a name that conflicts with an internal container property (like ``'nwbdatainterface'`` or ``'dynamictable'`` from :class:`types.core.ProcessingModule`, not recommended), MatNWB will automatically append an underscore:

.. code-block:: MATLAB

    someObject = types.core.TimeSeries();

    % This name conflicts with an internal container property
    processingModule.add('nwbdatainterface', someObject);
    
    % Access it with an underscore appended
    someObject = processingModule.nwbdatainterface_;

Duplicate names
~~~~~~~~~~~~~~~
If you add multiple objects with the same name (case-insensitive), MatNWB will append numeric suffixes to create unique property names:

.. code-block:: MATLAB

    % Add multiple objects with the same name (same alias)
    processingModule = types.core.ProcessingModule('description', 'My processing module');
    processingModule.add('My_Data', types.core.TimeSeries());
    processingModule.add('My-Data', types.core.TimeSeries());
    processingModule.add('My.Data', types.core.TimeSeries());

    % Access them with unique property names
    data1 = processingModule.My_Data;       % Original
    data2 = processingModule.My_Data_1;     % First duplicate
    data3 = processingModule.My_Data_2;     % Second duplicate

Name not found error
~~~~~~~~~~~~~~~~~~~~

If you try to access a property that doesn't exist, you'll get an error. Always check first or handle the error:

.. code-block:: MATLAB

    % Check before accessing
    if isprop(processingModule, 'MyData')
        dataObject = processingModule.MyData;
    else
        warning('MyData not found in processingModule');
    end

.. tip::

    Remember to use the MATLAB property name (alias), not the original name, when checking with ``isprop()``.

Advanced Topics
---------------

Legacy Syntax (Deprecated)
--------------------------

.. note:: 

    The legacy ``.set()`` and ``.get()`` methods are deprecated. Use ``add()`` and dot-indexing instead.

For users familiar with older versions of MatNWB, the legacy syntax is still supported for backward compatibility:

.. code-block:: MATLAB

    dataObject = types.core.TimeSeries();

    % Deprecated: add to Set directly
    processingModule.nwbdatainterface.set('MyData', dataObject);
    
    % Recommended: use add() method
    processingModule.add('MyData', dataObject);
    
    % Deprecated: get from Set
    dataObject = processingModule.nwbdatainterface.get('MyData');
    
    % Recommended: direct property access
    dataObject = processingModule.MyData;


Working with Sets directly
~~~~~~~~~~~~~~~~~~~~~~~~~~

You can still access the underlying ``types.untyped.Set`` objects directly:

.. code-block:: MATLAB

    % Access the Set directly
    dataSet = processingModule.nwbdatainterface;
    
    % Set supports direct property access
    dataObject = dataSet.MyData;
    
    % Check what's in the Set
    allKeys = dataSet.keys();
    allValues = dataSet.values();
    hasKey = dataSet.isKey('MyData');

.. seealso::

    For more information about the underlying Set implementation, see :ref:`matnwb-read-untyped-sets-anons`.
