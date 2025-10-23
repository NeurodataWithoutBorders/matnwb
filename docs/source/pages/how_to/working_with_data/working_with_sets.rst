.. _howto-working-with-sets:

Work with Sets
==============

How to add, access, and manage data objects stored in Set containers within NWB files.

Prerequisites
-------------
* MatNWB installed and on the MATLAB path.
* Basic familiarity with creating NWB objects (see the MatNWB tutorials if needed).

.. contents:: On this page
    :local:
    :depth: 2

At a glance
-----------
Sets are containers used throughout NWB to store named collections of data objects. Common examples include:

- ``acquisition`` - stores raw data acquisition objects (e.g., ``TimeSeries``, ``ImageSeries``)
- ``processing`` modules - contain ``nwbdatainterface`` and ``dynamictable`` Sets
- ``stimulus`` - stores stimulus presentation and template data

**Key operations:**

1. **Add entries** with the ``.add()`` method (recommended for new entries)
2. **Access entries** using dot syntax or the ``.get()`` method  
3. **Update entries** by reassigning via dot syntax
4. **List entries** with the ``.keys()`` method


Adding entries to a Set
-----------------------

Use the ``.add()`` method to add new data objects to a Set. This method ensures that each entry has a unique name.

.. code-block:: matlab

    % Create an NWB file
    nwb = NwbFile( ...
        'identifier', 'sets-howto-20251023T120000Z', ...
        'session_description', 'Working with Sets example', ...
        'session_start_time', datetime(2025,10,23,12,0,0,'TimeZone','UTC'));
    
    % Create a TimeSeries object
    timeseries = types.core.TimeSeries( ...
        'data', rand(100, 1), ...
        'data_unit', 'meters', ...
        'starting_time', 0.0, ...
        'starting_time_rate', 30.0);
    
    % Add the TimeSeries to the acquisition Set
    nwb.acquisition.add('SpatialSeries', timeseries);

The ``.add()`` method will raise an error if you try to add an entry with a name that already exists:

.. code-block:: matlab

    % This will raise an error: NWB:Set:KeyExists
    anotherTimeseries = types.core.TimeSeries( ...
        'data', rand(50, 1), ...
        'data_unit', 'volts', ...
        'starting_time', 0.0, ...
        'starting_time_rate', 1000.0);
    
    nwb.acquisition.add('SpatialSeries', anotherTimeseries);  % Error!


Accessing entries from a Set
----------------------------

Once entries are added to a Set, you can access them using dot syntax with the entry name:

.. code-block:: matlab

    % Access the TimeSeries using dot syntax
    retrievedTimeseries = nwb.acquisition.SpatialSeries;
    
    % Access the data within the TimeSeries
    data = retrievedTimeseries.data;

Alternatively, you can use the ``.get()`` method:

.. code-block:: matlab

    % Access using the get method
    retrievedTimeseries = nwb.acquisition.get('SpatialSeries');


Checking if an entry exists
---------------------------

Use the ``.isKey()`` method to check whether an entry exists in a Set:

.. code-block:: matlab

    if nwb.acquisition.isKey('SpatialSeries')
        disp('SpatialSeries exists in acquisition');
    end


Listing all entries in a Set
----------------------------

Use the ``.keys()`` method to get a list of all entry names in a Set:

.. code-block:: matlab

    % Get all entry names
    allAcquisitionNames = nwb.acquisition.keys();
    
    % Display the names
    disp('Acquisition objects:');
    disp(allAcquisitionNames);


Updating entries in a Set
-------------------------

You can update an existing entry by reassigning it using dot syntax:

.. code-block:: matlab

    % Create a new TimeSeries to replace the existing one
    updatedTimeseries = types.core.TimeSeries( ...
        'data', rand(200, 1), ...
        'data_unit', 'meters', ...
        'starting_time', 0.0, ...
        'starting_time_rate', 30.0);
    
    % Update the existing entry
    nwb.acquisition.SpatialSeries = updatedTimeseries;

.. NOTE::
   The ``.add()`` method cannot be used to update existing entries. Use dot syntax assignment instead.


Removing entries from a Set
---------------------------

Use the ``.remove()`` method to delete entries from a Set:

.. code-block:: matlab

    % Remove a single entry
    nwb.acquisition.remove('SpatialSeries');
    
    % Remove multiple entries at once
    nwb.acquisition.remove({'Entry1', 'Entry2'});


Working with processing modules
-------------------------------

Processing modules are a common use case for Sets. They contain two Sets: ``nwbdatainterface`` and ``dynamictable``.

.. code-block:: matlab

    % Create a processing module
    behaviorModule = types.core.ProcessingModule( ...
        'description', 'Contains behavioral data');
    
    % Create a Position object
    position = types.core.Position();
    
    % Create a SpatialSeries for position data
    positionSeries = types.core.SpatialSeries( ...
        'data', rand(100, 2), ...
        'reference_frame', 'top-left corner of room', ...
        'data_unit', 'meters', ...
        'starting_time', 0.0, ...
        'starting_time_rate', 30.0);
    
    % Add the SpatialSeries to the Position object
    position.spatialseries.add('Position', positionSeries);
    
    % Add the Position object to the processing module's nwbdatainterface Set
    behaviorModule.nwbdatainterface.add('Position', position);
    
    % Add the processing module to the NWB file
    nwb.processing.set('behavior', behaviorModule);


Naming conventions
------------------

Following consistent naming conventions helps ensure that your NWB files are interoperable and easy to understand.

**Best practices from NWB Inspector:**

- Use descriptive, informative names that indicate the content or purpose of the data object
- Use **PascalCase** (capitalize each word, no spaces) for object names: ``SpatialSeries``, ``MotionCorrection``
- Avoid generic names like ``data``, ``timeseries``, or ``obj1``
- Be specific: instead of ``TimeSeries``, use ``LeverPosition`` or ``PupilDiameter``
- For multiple similar objects, use descriptive suffixes: ``LeftEyeTracking``, ``RightEyeTracking``

**Examples of good naming:**

.. code-block:: matlab

    nwb.acquisition.add('LeverPosition', leverTimeseries);
    nwb.acquisition.add('PupilDiameter', pupilTimeseries);
    behaviorModule.nwbdatainterface.add('EyeTracking', eyeTrackingData);

**Examples of poor naming:**

.. code-block:: matlab

    nwb.acquisition.add('ts1', timeseries1);  % Too generic
    nwb.acquisition.add('data', mydata);      % Not descriptive
    nwb.acquisition.add('obj', myobject);     % Meaningless

For more details, see the `NWB Inspector naming conventions <https://nwbinspector.readthedocs.io/en/dev/best_practices/general.html#naming-conventions>`_.


Handling naming conflicts
--------------------------

MATLAB requires that property names be valid identifiers (start with a letter, contain only letters, numbers, and underscores). When you add an entry to a Set with a name that is not a valid MATLAB identifier, MatNWB automatically creates a valid property name while preserving the original name for file export.

**Invalid characters are replaced:**

.. code-block:: matlab

    % Add an entry with a hyphen (not valid in MATLAB identifiers)
    behaviorModule.nwbdatainterface.add('Eye-Tracking', eyeData);
    
    % Access using the modified property name (hyphen replaced with underscore)
    retrievedData = behaviorModule.nwbdatainterface.Eye_Tracking;
    
    % The original name is preserved for export and can be retrieved
    originalName = behaviorModule.nwbdatainterface.keys();  % Returns 'Eye-Tracking'

**Name collision handling:**

If two entries would result in the same valid MATLAB identifier, MatNWB appends a numeric suffix:

.. code-block:: matlab

    % Add entries with names that become identical when converted
    behaviorModule.nwbdatainterface.add('Time_Series', ts1);
    behaviorModule.nwbdatainterface.add('Time-Series', ts2);
    
    % MatNWB creates unique property names
    data1 = behaviorModule.nwbdatainterface.Time_Series;    % First entry
    data2 = behaviorModule.nwbdatainterface.Time_Series_1;  % Second entry with suffix

**Alias warning:**

When you display an object with modified property names, MatNWB shows a warning with a table mapping property identifiers to original names:

.. code-block:: matlab

    >> disp(behaviorModule)
    
    ProcessingModule with entries:
        Eye_Tracking: types.core.EyeTracking
    
    Warning: Names for some entries of "ProcessingModule" have been modified to 
    make them valid MATLAB identifiers before adding them as properties of the 
    object. The original names will still be used when data is exported to file:
    
         ValidIdentifier    OriginalName  
         _______________    _____________
         "Eye_Tracking"     "Eye-Tracking"

.. TIP::
   To avoid naming conflicts and maintain clarity, always use valid MATLAB identifiers following PascalCase conventions when naming your entries.


Complete example
----------------

Here's a complete example demonstrating the workflow of working with Sets:

.. code-block:: matlab

    % Create an NWB file
    nwb = NwbFile( ...
        'identifier', 'complete-sets-example', ...
        'session_description', 'Complete Sets workflow example', ...
        'session_start_time', datetime(2025,10,23,12,0,0,'TimeZone','UTC'));
    
    % Add raw acquisition data
    rawData = types.core.TimeSeries( ...
        'data', rand(1000, 1), ...
        'data_unit', 'volts', ...
        'starting_time', 0.0, ...
        'starting_time_rate', 30000.0);
    nwb.acquisition.add('RawElectricalSeries', rawData);
    
    % Create a processing module for filtered data
    ecephysModule = types.core.ProcessingModule( ...
        'description', 'Processed electrophysiology data');
    
    % Add filtered data
    filteredData = types.core.TimeSeries( ...
        'data', rand(1000, 1), ...
        'data_unit', 'volts', ...
        'starting_time', 0.0, ...
        'starting_time_rate', 30000.0);
    
    ecephysModule.nwbdatainterface.add('FilteredElectricalSeries', filteredData);
    
    % Add the processing module to the NWB file
    nwb.processing.set('ecephys', ecephysModule);
    
    % List all acquisition objects
    disp('Acquisition objects:');
    disp(nwb.acquisition.keys());
    
    % Check if a specific object exists
    if nwb.acquisition.isKey('RawElectricalSeries')
        % Retrieve and work with the data
        raw = nwb.acquisition.RawElectricalSeries;
        disp(['Raw data length: ' num2str(length(raw.data))]);
    end
    
    % Export the file
    nwbExport(nwb, 'complete_sets_example.nwb');


Summary
-------
Sets provide a flexible way to organize and access collections of data objects in NWB files. Use the ``.add()`` method for adding new entries, dot syntax for accessing and updating entries, and follow PascalCase naming conventions for interoperability. MatNWB automatically handles naming conflicts by creating valid MATLAB identifiers while preserving original names for file export.


See also
--------
- :ref:`tutorials` - Learn more about creating NWB files
- `NWB Inspector best practices <https://nwbinspector.readthedocs.io/en/dev/best_practices/general.html>`_
