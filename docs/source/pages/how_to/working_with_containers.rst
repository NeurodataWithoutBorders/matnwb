.. _how_to_working_with_containers:

Working with Container Properties and Types
===========================================

This guide shows you how to work with NWB properties and types that is designed to hold other data objects (containers).

.. contents::
   :local:
   :depth: 2

Overview
--------
Some neurodata types and properties of neurodata types in NWB are designed to hold one or more data objects of specific types. We will refer to these neurodata types and properties as **containers**. For example, both the ``acquisition`` property of a :class:`types.core.NWBFile` and the :class:`types.core.ProcessingModule` neurodata type can contain multiple data objects of :class:`types.core.NWBDataInterface` or :class:`types.hdmf_common.DynamicTable` types (including subtypes). 

Each data object stored in a container is called an **entry**. Entries are identified by unique names that you assign when adding them to the container. A container is represented internally using the :class:`types.untyped.Set` class and MatNWB provides convenient syntax that mimics standard MATLAB property access for working with these containers and their entries.

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

    **Best practice:** Use names that are valid MATLAB identifiers from the start (e.g., PascalCase, camelCase or snake_case) and stick to one style:
    
    .. code-block:: MATLAB
    
        processingModule.add('MyTimeSeries', timeSeries);
        processingModule.add('myTimeSeries', timeSeries);
        processingModule.add('my_time_series', timeSeries);

If you read files created by other tools with names that are not valid MATLAB identifiers, MatNWB will automatically create valid MATLAB identifiers (aliases) when loading the data.

Viewing name mappings (aliases)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a container contains entries with names that are not valid MATLAB identifiers, a warning will display showing the mapping between original names and property names (aliases) when the container type is displayed in MATLAB's command window.

.. code-block:: MATLAB

    % Create a processing module
    processingModule = types.core.ProcessingModule('description', 'My processing module');
    
    % Add with spaces and special characters
    processingModule.add('my time series', timeSeries);
    processingModule.add('data-table', dataTable);
    disp(processingModule)

**Output:**

.. code-block:: matlabsession

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

    nameMap = processingModule.getAliasMap();

**Output:**

.. code-block:: matlabsession

    >> nameMap

    nameMap =

    2×2 table

        ValidIdentifier      OriginalName  
        _______________    ________________

        "data_table"       "data-table"    
        "myTimeSeries"     "my time series"

.. note::

    In addition to using alias names for property access, you can also use ``.get()`` and ``.set()`` methods (legacy syntax) on the underlying ``types.untyped.Set`` objects with the original names (see :ref:`set-methods-with-invalid-names`).

Troubleshooting
---------------

Property name conflicts
~~~~~~~~~~~~~~~~~~~~~~~

If you add an entry with a name that conflicts with an internal container property—e.g., 'nwbdatainterface' or 'dynamictable' from :class:types.core.ProcessingModule—MatNWB will automatically append an underscore. Note that using such names is not recommended.

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

Working with Sets directly
~~~~~~~~~~~~~~~~~~~~~~~~~~

Containers are represented internally using ``types.untyped.Set`` objects. While the recommended approach is to use the ``add()`` method and dot-indexing for accessing container entries, you can also work with the underlying ``types.untyped.Set`` objects directly.


Using Set methods
^^^^^^^^^^^^^^^^^

The ``types.untyped.Set`` object provides ``set`` and ``get`` methods for managing entries of a container:

.. code-block:: MATLAB

    dataObject = types.core.TimeSeries();
    
    % Add to Set using set() method
    processingModule.nwbdatainterface.set('MyData', dataObject);
    
    % Get from Set using get() method
    dataObject = processingModule.nwbdatainterface.get('MyData');
    
.. note::

    While working with ``types.untyped.Set`` objects directly is fully supported, using the ``add()`` method and dot-indexing provides a more intuitive and MATLAB-like syntax for most use cases.

The ``types.untyped.Set`` class also provides additional methods for inspecting entries, such as ``keys()``, ``values()``, and ``isKey()``:

.. code-block:: MATLAB

    % Check what's in the Set
    allKeys = processingModule.nwbdatainterface.keys();
    allValues = processingModule.nwbdatainterface.values();
    hasKey = processingModule.nwbdatainterface.isKey('MyData');

.. _set-methods-with-invalid-names:

Using Set methods with invalid MATLAB names
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

One advantage of using ``types.untyped.Set`` methods is that you can use the **original names** directly, even if they are not valid MATLAB identifiers:

.. code-block:: MATLAB

    % Create a processing module
    processingModule = types.core.ProcessingModule('description', 'My processing module');
    
    % Add objects using original names with spaces and special characters
    timeSeries = types.core.TimeSeries( ... 
        'data', rand(100, 1), ...
        'data_unit', 'volts', ...
        'timestamps', linspace(0, 1, 100));
    
    dataTable = types.hdmf_common.DynamicTable( ...
        'description', 'My data table');

    processingModule.nwbdatainterface.set('my time series', timeSeries);
    processingModule.dynamictable.set('data-table', dataTable);
    
    % Retrieve using original names
    timeSeries = processingModule.nwbdatainterface.get('my time series');
    dataTable = processingModule.dynamictable.get('data-table');

.. seealso::

    For more information about the underlying ``types.untyped.Set`` implementation, see :ref:`matnwb-read-untyped-sets-anons`.

Container Display Modes
~~~~~~~~~~~~~~~~~~~~~~~

MatNWB provides different display modes for container types to control how entries are shown in the MATLAB command window:

    - ``'groups'`` (default): Displays container entries in nested groups.
    - ``'flat'``: Displays all entries directly without nesting.
    - ``'legacy'``: Mimics the behavior of older MatNWB versions.

You can change the display mode using MATLAB's ``setpref`` function with the preference group ``'matnwb'`` and preference name ``'ContainerDisplayMode'``.

Create a processing module with some entries and see the different display modes:
    
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

Groups display mode (default)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

By default, MatNWB displays container properties (Sets) in a nested (``'groups'``) form:

.. code-block:: matlabsession

    >> processingModule

    processingModule = 

    ProcessingModule with properties:

        description: 'My processing module'

    nwbdatainterface group with 1 entry:
        NeuralActivity: [1×1 types.core.TimeSeries]

    dynamictable group with 1 entry:
            DataTable: [1×1 types.hdmf_common.DynamicTable]


Flat display mode
^^^^^^^^^^^^^^^^^

To see all entries directly without nesting, use the ``'flat'`` display mode:
        
.. code-block:: MATLAB

    % Set flat display mode
    setpref('matnwb', 'ContainerDisplayMode', 'flat');
    disp(processingModule);

**Output:**

.. code-block:: matlabsession

  ProcessingModule with properties:

       description: 'My processing module'
         DataTable: [1×1 types.hdmf_common.DynamicTable]
    NeuralActivity: [1×1 types.core.TimeSeries]

Legacy display mode
^^^^^^^^^^^^^^^^^^^

It is also possible to set the display mode to ``'legacy'``, which mimics the behavior of older MatNWB versions:
        
.. code-block:: MATLAB

    % Set legacy display mode
    setpref('matnwb', 'ContainerDisplayMode', 'legacy');
    disp(processingModule);

**Output:**

.. code-block:: matlabsession

    ProcessingModule with properties:

            description: 'My processing module'
        nwbdatainterface: [1×1 types.untyped.Set]
            dynamictable: [1×1 types.untyped.Set]
