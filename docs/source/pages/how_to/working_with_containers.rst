.. _how_to_working_with_containers:

Working with Container Types Using Dot-Indexing
================================================

This guide shows you how to work with NWB container types that hold multiple data objects using convenient dot-indexing syntax instead of the legacy ``.set()`` and ``.get()`` methods.

.. contents::
   :local:
   :depth: 2

Overview
--------

Some NWB container types (like ``ProcessingModule``) are designed to hold multiple data objects of specific types. In older versions of MatNWB, you had to use ``.set()`` and ``.get()`` methods to add and retrieve these objects. Modern MatNWB provides more convenient syntax that mimics standard MATLAB property access.

**Legacy approach:**

.. code-block:: MATLAB

    % Adding data
    module.nwbdatainterface.set('MyTimeSeries', timeSeriesObject);
    
    % Retrieving data
    timeSeries = module.nwbdatainterface.get('MyTimeSeries');

**Modern approach:**

.. code-block:: MATLAB

    % Adding data
    module.add('MyTimeSeries', timeSeriesObject);
    
    % Retrieving data
    timeSeries = module.MyTimeSeries;

Adding Data Objects
-------------------

Using the add() method
~~~~~~~~~~~~~~~~~~~~~~

The ``add()`` method is the recommended way to add data objects to container types:

.. code-block:: MATLAB

    % Create a processing module
    module = types.core.ProcessingModule('description', 'My analysis module');
    
    % Create some data objects
    timeSeries = types.core.TimeSeries( ...
        'data', rand(100, 1), ...
        'data_unit', 'volts', ...
        'timestamps', linspace(0, 1, 100));
    
    dataTable = types.hdmf_common.DynamicTable( ...
        'description', 'My data table');
    
    % Add them to the module
    module.add('NeuralActivity', timeSeries);
    module.add('ResultsTable', dataTable);

During construction
~~~~~~~~~~~~~~~~~~~

You can also add data objects when creating the container:

.. code-block:: MATLAB

    module = types.core.ProcessingModule( ...
        'description', 'My analysis module', ...
        'NeuralActivity', timeSeries, ...
        'ResultsTable', dataTable);

Accessing Data Objects
-----------------------

Direct property access
~~~~~~~~~~~~~~~~~~~~~~

Once added, data objects are accessible as properties of the container:

.. code-block:: MATLAB

    % Retrieve by property name
    timeSeries = module.NeuralActivity;
    resultsTable = module.ResultsTable;
    
    % You can then access their properties
    data = timeSeries.data;
    timestamps = timeSeries.timestamps;

This works exactly like accessing any other MATLAB object property, making your code more readable and intuitive.

Checking if an object exists
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use ``isprop()`` to check if a data object exists:

.. code-block:: MATLAB

    if isprop(module, 'NeuralActivity')
        timeSeries = module.NeuralActivity;
    end

Removing Data Objects
----------------------

Use the ``remove()`` method to remove data objects:

.. code-block:: MATLAB

    % Remove a data object by its name
    module.remove('NeuralActivity');
    
    % Verify it's gone
    hasProperty = isprop(module, 'NeuralActivity');  % Returns false

.. note::

    The ``remove()`` method only removes objects from memory. It does not remove neurodata objects from files that have been read from disk. To modify the contents of an existing NWB file, you need to create a new file with the desired changes.

Working with Names
------------------

Handling invalid MATLAB names
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

MATLAB property names must follow specific rules (no spaces, special characters, must start with a letter, etc.). When you add a data object with a name that isn't a valid MATLAB identifier, MatNWB automatically creates a valid alias:

.. code-block:: MATLAB

    % Add with spaces and special characters
    module.add('my time series', timeSeries);
    module.add('Raw-Fluorescence', fluorescence);
    
    % Access using valid MATLAB identifiers
    timeSeries = module.myTimeSeries;        % Spaces removed, camelCase
    fluorescence = module.RawFluorescence;  % Hyphen replaced with uppercase

.. important::

    The **original name** is preserved in the NWB file. Other tools (like PyNWB) will see ``'my time series'`` and ``'Raw-Fluorescence'``, not the MATLAB aliases.

.. tip::

    **Best practice:** Use names that are valid MATLAB identifiers from the start (e.g., PascalCase or camelCase) to avoid confusion:
    
    .. code-block:: MATLAB
    
        module.add('MyTimeSeries', timeSeries);
        module.add('RawFluorescence', fluorescence);

Viewing name mappings
~~~~~~~~~~~~~~~~~~~~~

If MatNWB creates aliases, it will display a warning showing the mapping between original names and property names. You can also check the ``nwbdatainterface`` or ``dynamictable`` properties to see the original names:

.. code-block:: MATLAB

    % See all original names in the Set
    originalNames = module.nwbdatainterface.keys();
    
    % Get the mapping table
    mappingTable = module.nwbdatainterface.getPropertyMappingTable();

Understanding Container Types
------------------------------

ProcessingModule
~~~~~~~~~~~~~~~~

The most common container type is ``ProcessingModule``, which can hold:

- **NWBDataInterface objects** (stored in ``nwbdatainterface`` property)
- **DynamicTable objects** (stored in ``dynamictable`` property)

.. code-block:: MATLAB

    module = types.core.ProcessingModule('description', 'Optical physiology module');
    
    % Add a NWBDataInterface subclass
    module.add('Fluorescence', types.core.Fluorescence());
    
    % Add a DynamicTable
    module.add('RegionOfInterestTable', types.hdmf_common.DynamicTable( ...
        'description', 'Region of interest properties'));

The ``add()`` method automatically determines which internal Set (``nwbdatainterface`` or ``dynamictable``) to use based on the object's type.

Working with Sets directly (advanced)
--------------------------------------

For advanced use cases, you can still access the underlying ``types.untyped.Set`` objects directly:

.. code-block:: MATLAB

    % Access the Set directly
    dataSet = module.nwbdatainterface;
    
    % Legacy methods still work
    dataSet.set('MyData', dataObject);
    dataObject = dataSet.get('MyData');
    
    % Set also supports direct property access
    dataObject = dataSet.MyData;
    
    % Check what's in the Set
    allKeys = dataSet.keys();
    allValues = dataSet.values();
    hasKey = dataSet.isKey('MyData');

.. seealso::

    For more information about the underlying Set implementation, see :ref:`matnwb-read-untyped-sets-anons`.

Legacy Syntax Support
---------------------

All legacy syntax is still supported for backward compatibility:

.. code-block:: MATLAB

    % Legacy: add to Set directly
    module.nwbdatainterface.set('MyData', dataObject);
    
    % Modern: use add() method
    module.add('MyData', dataObject);
    
    % Legacy: get from Set
    dataObject = module.nwbdatainterface.get('MyData');
    
    % Modern: direct property access
    dataObject = module.MyData;

Complete Example
----------------

Here's a complete workflow showing modern syntax:

.. code-block:: MATLAB

    % Create NWB file
    nwbFile = NwbFile( ...
        'session_description', 'My experiment', ...
        'identifier', 'exp001', ...
        'session_start_time', datetime());
    
    % Create a processing module
    opticalPhysiologyModule = types.core.ProcessingModule( ...
        'description', 'Optical physiology data');
    
    % Create and add data objects
    fluorescence = types.core.Fluorescence();
    roiResponseSeries = types.core.RoiResponseSeries( ...
        'data', rand(100, 10), ...
        'data_unit', 'lumens', ...
        'timestamps', linspace(0, 10, 100));
    
    fluorescence.add('RoiResponseSeries', roiResponseSeries);
    opticalPhysiologyModule.add('Fluorescence', fluorescence);
    
    % Add module to NWB file
    nwbFile.processing.set('ophys', opticalPhysiologyModule);
    
    % Later, retrieve your data using dot-indexing
    fluorescence = opticalPhysiologyModule.Fluorescence;
    roiResponseSeries = fluorescence.RoiResponseSeries;
    traces = roiResponseSeries.data;
    
    % Export the file
    nwbExport(nwbFile, 'my_experiment.nwb');

Troubleshooting
---------------

Property name conflicts
~~~~~~~~~~~~~~~~~~~~~~~

If you try to add an object with a name that conflicts with an internal container property (like ``'nwbdatainterface'`` or ``'dynamictable'``), MatNWB will automatically append an underscore:

.. code-block:: MATLAB

    % This name conflicts with an internal container property
    module.add('nwbdatainterface', someObject);
    
    % Access it with an underscore appended
    someObject = module.nwbdatainterface_;

Name not found error
~~~~~~~~~~~~~~~~~~~~

If you try to access a property that doesn't exist, you'll get an error. Always check first or handle the error:

.. code-block:: MATLAB

    % Check before accessing
    if isprop(module, 'MyData')
        dataObject = module.MyData;
    else
        warning('MyData not found in module');
    end

.. tip::

    Remember to use the MATLAB property name (alias), not the original name, when checking with ``isprop()``.
