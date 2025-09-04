.. _hdf5-considerations:

HDF5 Considerations and Limitations
===================================

NWB files are stored in HDF5 format, which provides excellent performance and portability but comes with important limitations that affect how you create and modify files. Understanding these constraints is essential for effective NWB file management.

.. warning::
    **Critical HDF5 Limitations**
    
    - Files cannot be easily modified after creation
    - Adding new datasets requires specialized approaches
    - Concurrent access by multiple processes is not supported  
    - Schema changes require recreating the entire file
    - Large datasets need careful memory management

File Modification Challenges
----------------------------

**The Core Problem:**

Unlike simple text files, HDF5 files have a complex internal structure that makes modifications difficult:

.. code-block:: MATLAB

    % This workflow is PROBLEMATIC:
    
    % Day 1: Create initial file
    nwb = create_basic_nwb_file();
    nwbExport(nwb, 'experiment.nwb');
    
    % Day 2: Try to add more data (DIFFICULT!)
    nwb = nwbRead('experiment.nwb');
    % Adding new acquisition data here is complex and error-prone
    new_data = record_more_data();
    % nwb.acquisition.set('day2_data', new_data);  % Not straightforward!
    % nwbExport(nwb, 'experiment.nwb');  % May corrupt the file

**Why Modification is Difficult:**

1. **Fixed internal structure** - HDF5 pre-allocates space for datasets
2. **Metadata dependencies** - Changes can break internal links and references  
3. **Compression conflicts** - Compressed data cannot be easily extended
4. **Schema validation** - New data must maintain consistency with existing structure

Strategies for File Modification
---------------------------------

**Strategy 1: Plan for Incremental Data (Recommended)**

Design your workflow to accommodate all expected data from the start:

.. code-block:: MATLAB

    % Create file structure for ALL expected data upfront
    nwb = NwbFile( ...
        'session_start_time', datetime('now', 'TimeZone', 'local'), ...
        'identifier', 'session_001', ...
        'session_description', 'Multi-day recording session');
    
    % Pre-allocate space for time series that will grow
    initial_data = zeros(0, 32);  % Start with 0 timepoints, 32 channels
    max_timepoints = 1000000;     % But plan for up to 1M timepoints
    
    data_pipe = types.untyped.DataPipe( ...
        'data', initial_data, ...
        'maxSize', [max_timepoints, 32], ...  % Reserve space
        'axis', 1);  % Allow growth along time axis
    
    electrical_series = types.core.ElectricalSeries( ...
        'data', data_pipe, ...
        'electrodes', electrode_region, ...
        'starting_time', 0.0, ...
        'starting_time_rate', 30000.0);
    
    nwb.acquisition.set('extracellular', electrical_series);
    nwbExport(nwb, 'experiment.nwb');
    
    % Later: Append new data incrementally
    nwb = nwbRead('experiment.nwb', 'ignorecache');
    new_chunk = record_next_data_chunk();
    nwb.acquisition.get('extracellular').data.append(new_chunk);

**Strategy 2: Separate Files for Each Session**

Keep each recording session in its own file:

.. code-block:: MATLAB

    % Better approach: separate files
    for session = 1:num_sessions
        nwb = create_session_nwb(session);
        filename = sprintf('experiment_session_%03d.nwb', session);
        nwbExport(nwb, filename);
    end
    
    % Analysis code reads multiple files as needed
    all_sessions = {};
    for session = 1:num_sessions
        filename = sprintf('experiment_session_%03d.nwb', session);
        all_sessions{session} = nwbRead(filename);
    end

**Strategy 3: Recreate Files When Necessary**

For significant additions, recreate the entire file:

.. code-block:: MATLAB

    % Read existing data
    old_nwb = nwbRead('experiment_v1.nwb');
    
    % Create new file with old + new data
    new_nwb = NwbFile( ...
        'session_start_time', old_nwb.session_start_time, ...
        'identifier', old_nwb.identifier, ...
        'session_description', old_nwb.session_description);
    
    % Copy existing data
    copy_data_objects(old_nwb, new_nwb);
    
    % Add new data
    new_nwb.acquisition.set('additional_recording', new_electrical_series);
    
    % Export new version
    nwbExport(new_nwb, 'experiment_v2.nwb');

Edit Mode vs. Overwrite Mode
----------------------------

MatNWB provides two export modes with different behaviors:

.. code-block:: MATLAB

    % Overwrite mode (default): Creates new file, replacing any existing file
    nwbExport(nwb, 'data.nwb', 'overwrite');
    
    % Edit mode: Attempts to modify existing file (LIMITED FUNCTIONALITY)
    nwbExport(nwb, 'data.nwb', 'edit');

**Edit Mode Limitations:**

- Can only modify certain metadata fields
- Cannot add new datasets or change data structure  
- Cannot resize existing datasets
- Primarily useful for updating file creation timestamps

.. warning::
    Edit mode is **not** a general solution for file modification. It should only be used for minor metadata updates.


Concurrent Access Limitations  
-----------------------------

**Problem: Multiple Processes Cannot Write Simultaneously**

.. code-block:: MATLAB

    % This will fail if run simultaneously:
    
    % Process 1:
    nwb1 = nwbRead('shared_file.nwb');
    % ... modify nwb1 ...
    nwbExport(nwb1, 'shared_file.nwb');  % Will lock file
    
    % Process 2 (running at same time):
    nwb2 = nwbRead('shared_file.nwb');   % May fail or get corrupted data
    % ... modify nwb2 ...
    nwbExport(nwb2, 'shared_file.nwb');  % Will overwrite Process 1's changes!

**Solutions for Concurrent Workflows:**

1. **Use separate files per process:**

.. code-block:: MATLAB

    % Each process writes to its own file
    process_id = get_process_id();
    filename = sprintf('data_process_%d.nwb', process_id);
    nwbExport(nwb, filename);
    
    % Combine files later in post-processing step

2. **Coordinate access with file locking:**

.. code-block:: MATLAB

    function safe_nwb_append(filename, new_data)
        lock_file = [filename '.lock'];
        
        % Wait for exclusive access
        while exist(lock_file, 'file')
            pause(0.1);
        end
        
        % Create lock
        fclose(fopen(lock_file, 'w'));
        
        try
            % Perform file operation
            nwb = nwbRead(filename);
            nwb.acquisition.get('data').data.append(new_data);
            % Note: this may still fail due to HDF5 limitations
            
        finally
            % Always release lock
            if exist(lock_file, 'file')
                delete(lock_file);
            end
        end
    end

Schema Consistency Requirements
-------------------------------

**The Problem:**

HDF5 requires that data structure remains consistent with the schema:

Scenario:
- Read a previously generated file to make changes with ignorecache
- Current types are of different schema version
- Create new types and add to file

Working Within HDF5 Constraints
-------------------------------

**Recommended Workflow:**

1. **Plan your complete data structure upfront**
2. **Use separate files for truly independent data**  
3. **Pre-allocate space for datasets that will grow**

Understanding these HDF5 limitations will help you design robust workflows that work reliably with NWB files. The next section covers performance optimization strategies that work within these constraints.
