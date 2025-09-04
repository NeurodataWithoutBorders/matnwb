.. _matnwb-create-nwbfile-intro:

Creating the NwbFile Object
===========================

The :class:`NwbFile` object is the root container for all data in an NWB file. Before adding any experimental data, you must create this object and add the required metadata properties.

Required properties
-------------------

The NWB file must contain three required properties that needs to be manually specified:

1. **session_start_time** (:class:`datetime`) - When the experiment began, with timezone information
2. **identifier** (:class:`char`) - A unique identifier for this specific session/file
3. **session_description** (:class:`char`) - Brief description of the experimental session

**Example:**

.. code-block:: MATLAB

    nwb = NwbFile( ...
        'session_start_time', datetime('2024-01-15 09:30:00', 'TimeZone', 'local'), ...
        'identifier', 'Mouse001_Session_20240115', ...
        'session_description', 'Two-photon calcium imaging during whisker stimulation');

Two additional required properties are set automatically if not provided:

- **file_create_date** - Automatically set to the current time when the file is exported
- **timestamps_reference_time** - Defaults to match ``session_start_time`` if not explicitly set

Recommended Metadata Properties
-------------------------------

While not required, these properties provide important context for your data:

- **general_experimenter** - Who conducted the experiment
- **general_institution** - Where the experiment was performed  
- **general_lab** - Which laboratory/group
- **general_session_id** - Lab-specific session identifier
- **general_experiment_description** - Detailed experimental context

**Example:**

.. code-block:: MATLAB

    nwb = NwbFile( ...
        'session_start_time', datetime('2024-01-15 09:30:00', 'TimeZone', 'local'), ...
        'identifier', 'Mouse001_Session_20240115', ...
        'session_description', 'Two-photon calcium imaging during whisker stimulation', ...
        'general_experimenter', 'Dr. Jane Smith', ...
        'general_institution', 'University Research Institute', ...
        'general_lab', 'Neural Circuits Lab', ...
        'general_session_id', 'session_001', ...
        'general_experiment_description', 'Investigation of sensory processing in barrel cortex');


Subject Information
-------------------

Information about the experimental subject should be added using the :class:`types.core.Subject` class:

.. code-block:: MATLAB

    % Create subject information
    subject = types.core.Subject( ...
        'subject_id', 'Mouse001', ...
        'age', 'P90', ...  % Post-natal day 90
        'description', 'C57BL/6J mouse', ...
        'species', 'Mus musculus', ...
        'sex', 'M');
    
    % Add to NWB file
    nwb.general_subject = subject;

Best Practices for Identifiers
------------------------------

**Session Identifiers:**

Choose identifiers that are:

- **Unique across your entire dataset** - avoid conflicts between labs, experiments, etc.
- **Informative** - include subject, date, session number when helpful
- **Consistent** - use a standardized naming scheme

.. code-block:: MATLAB

    % Good examples:
    identifier = 'SmithLab_Mouse001_20240115_Session01';
    identifier = 'MD5HASH_a1b2c3d4e5f6';  % For anonymization
    identifier = sprintf('%s_%s_%s', lab_id, subject_id, datestr(now, 'yyyymmdd'));

**Session Descriptions:**

Be specific and include:

- **Experimental paradigm** - what task or stimulation was used
- **Recording method** - electrophysiology, imaging, behavior only, etc.
- **Key experimental variables** - drug conditions, genotypes, etc.

.. code-block:: MATLAB

    % Good examples:
    session_description = 'Extracellular recordings in primary visual cortex during oriented grating presentation';
    session_description = 'Two-photon calcium imaging of layer 2/3 pyramidal neurons during whisker deflection';
    session_description = 'Behavioral training on auditory discrimination task, no neural recordings';

Time Zone Considerations
------------------------

NWB files store all timestamps in a standardized format. Always specify the timezone when creating datetime objects:

.. code-block:: MATLAB

    % Specify local timezone
    session_start = datetime('2024-01-15 09:30:00', 'TimeZone', 'America/New_York');
    
    % Or use UTC if preferred
    session_start = datetime('2024-01-15 14:30:00', 'TimeZone', 'UTC');
    
    % Current time with local timezone
    session_start = datetime('now', 'TimeZone', 'local');

The ``timestamps_reference_time`` field defines "time zero" for all timestamps in the file. This is typically set to match ``session_start_time``, but can be different if needed for your experimental design.

Validation
----------

The NwbFile and (included datatypes) will be validated when you attempt to export to file using the :func:`nwbExport` function. If any required properties are missing, an error will be raised.

.. code-block:: MATLAB

    % This will fail - missing required properties
    nwb = NwbFile();
    nwbExport(nwb, 'test.nwb');  % Error: missing identifier, session_description, etc.
    
    % This will succeed
    nwb = NwbFile( ...
        'session_start_time', datetime('now', 'TimeZone', 'local'), ...
        'identifier', 'test_session', ...
        'session_description', 'Test file');
    nwbExport(nwb, 'test.nwb');  % Success

Next Steps
----------

Once you have created an NwbFile object, you can begin adding experimental data. The next section covers how to organize different types of data within the NWB structure.
