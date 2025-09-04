Troubleshooting NWB File Creation
==================================

This section addresses common issues encountered when creating NWB files and provides solutions for typical problems. Many issues stem from the underlying HDF5 format constraints and can be avoided with proper planning.

Common Error Messages
---------------------

**"Required property not set" Errors:**

.. code-block:: text

    Error: The property 'session_start_time' is required but has not been set.

*Solution:* Ensure all required NwbFile properties are set before export:

.. code-block:: MATLAB

    % Fix: Set all required properties
    nwb = NwbFile( ...
        'session_start_time', datetime('now', 'TimeZone', 'local'), ...
        'identifier', 'unique_session_id', ...
        'session_description', 'Description of experiment');

**"Cannot modify existing file" Errors:**

.. code-block:: text

    Error: Unable to modify existing dataset in HDF5 file

*Problem:* Attempting to change data structure after file creation.

*Solution:* Recreate the file with the new structure:

.. code-block:: MATLAB

    % Don't try to modify existing files like this:
    % nwb = nwbRead('existing.nwb');
    % nwb.acquisition.set('new_data', new_dataset);  % This may fail
    
    % Instead, create a new file:
    old_nwb = nwbRead('existing.nwb');
    new_nwb = create_updated_nwb(old_nwb, new_data);
    nwbExport(new_nwb, 'updated_file.nwb');

**Out of Memory Errors:**

.. code-block:: text

    Error: Out of memory. Type "help memory" for your options.

*Problem:* Trying to load datasets larger than available RAM.

*Solution:* Use DataPipe for large datasets:

.. code-block:: MATLAB

    % Don't load huge datasets directly:
    % huge_data = load_entire_dataset();  % May exceed memory
    % electrical_series = types.core.ElectricalSeries('data', huge_data, ...);
    
    % Instead, use DataPipe for efficient handling:
    data_pipe = types.untyped.DataPipe( ...
        'data', initial_chunk, ...
        'maxSize', [total_samples, num_channels], ...
        'compressionLevel', 6);
    
    electrical_series = types.core.ElectricalSeries('data', data_pipe, ...);

File Corruption Issues
----------------------

**Symptoms of Corrupted Files:**

- File cannot be opened by nwbRead
- Incomplete data when reading
- Error messages about invalid HDF5 structure
- File size is much smaller than expected

**Prevention:**

.. code-block:: MATLAB

    function safe_nwb_export(nwb, filename)
        temp_filename = [filename, '.tmp'];
        
        try
            % Export to temporary file first
            nwbExport(nwb, temp_filename);
            
            % Verify the file can be read
            test_nwb = nwbRead(temp_filename);
            clear test_nwb;  % Release file handle
            
            % If successful, move to final location
            if exist(filename, 'file')
                backup_filename = [filename, '.backup'];
                movefile(filename, backup_filename);
            end
            movefile(temp_filename, filename);
            
            fprintf('File exported successfully: %s\n', filename);
            
        catch ME
            % Clean up on failure
            if exist(temp_filename, 'file')
                delete(temp_filename);
            end
            
            fprintf('Export failed: %s\n', ME.message);
            rethrow(ME);
        end
    end

**Recovery from Corruption:**

.. code-block:: MATLAB

    function recovered_data = recover_from_corrupted_nwb(corrupted_file)
        try
            % Try to read whatever is accessible
            nwb = nwbRead(corrupted_file);
            
            % Extract data that's still readable
            recovered_data = struct();
            
            % Try to recover metadata
            try
                recovered_data.session_start_time = nwb.session_start_time;
                recovered_data.identifier = nwb.identifier;
                recovered_data.session_description = nwb.session_description;
            catch
                warning('Could not recover basic metadata');
            end
            
            % Try to recover acquisition data
            try
                acquisition_keys = nwb.acquisition.keys();
                for key = acquisition_keys
                    try
                        data_obj = nwb.acquisition.get(key{1});
                        recovered_data.acquisition.(key{1}) = data_obj;
                    catch
                        warning('Could not recover acquisition data: %s', key{1});
                    end
                end
            catch
                warning('Could not access acquisition data');
            end
            
        catch ME
            error('File is too corrupted to recover: %s', ME.message);
        end
    end

Performance Problems
--------------------

**File Creation Takes Too Long:**

*Symptoms:* Export process runs for hours or appears to hang.

*Causes and Solutions:*

1. **Large uncompressed datasets:**

.. code-block:: MATLAB

    % Problem: No compression
    data_pipe = types.untyped.DataPipe('data', large_data);
    
    % Solution: Add compression
    data_pipe = types.untyped.DataPipe( ...
        'data', large_data, ...
        'compressionLevel', 6);

2. **Poor chunking strategy:**

.. code-block:: MATLAB

    % Problem: Inappropriate chunk size
    data_pipe = types.untyped.DataPipe( ...
        'chunkSize', [1, num_channels]);  % Too small chunks
    
    % Solution: Better chunk size
    data_pipe = types.untyped.DataPipe( ...
        'chunkSize', [1000, num_channels]);  % Larger, more efficient chunks

3. **Excessive memory allocation:**

.. code-block:: MATLAB

    % Problem: Loading all data at once
    all_data = load_entire_experiment();
    
    % Solution: Process in chunks
    chunk_size = 30000;  % 1 second at 30kHz
    for chunk_start = 1:chunk_size:total_samples
        chunk_end = min(chunk_start + chunk_size - 1, total_samples);
        chunk_data = load_data_chunk(chunk_start, chunk_end);
        append_to_nwb(nwb, chunk_data);
    end

**Files Are Too Large:**

*Problem:* NWB files much larger than source data.

*Solutions:*

1. **Increase compression:**

.. code-block:: MATLAB

    % Try higher compression levels
    data_pipe = types.untyped.DataPipe( ...
        'compressionLevel', 9);  % Maximum compression

2. **Use appropriate data types:**

.. code-block:: MATLAB

    % Convert to smaller data types if possible
    if max(data(:)) < 32767 && min(data(:)) > -32768
        compressed_data = int16(data);  % Use 16-bit instead of 64-bit
    end

3. **Remove unnecessary precision:**

.. code-block:: MATLAB

    % Round data to remove artificial precision
    rounded_data = round(data * 100) / 100;  % Keep 2 decimal places

Schema and Structure Issues
---------------------------

**"Invalid schema" Errors:**

*Problem:* Data doesn't match expected NWB structure.

*Common causes:*

1. **Incorrect data dimensions:**

.. code-block:: MATLAB

    % Problem: Wrong dimension order
    electrical_series = types.core.ElectricalSeries( ...
        'data', data);  % data should be [time x channels], not [channels x time]
    
    % Solution: Transpose if necessary
    if size(data, 1) < size(data, 2)  % More channels than timepoints is suspicious
        data = data';  % Transpose to [time x channels]
    end

2. **Missing linked objects:**

.. code-block:: MATLAB

    % Problem: Reference to non-existent object
    electrical_series = types.core.ElectricalSeries( ...
        'electrodes', electrode_region, ...  % electrode_region not properly created
        'data', data);
    
    % Solution: Ensure all linked objects exist
    electrode_table = create_electrode_table(electrode_info);
    electrode_region = types.hdmf_common.DynamicTableRegion( ...
        'table', types.untyped.ObjectView(electrode_table), ...
        'data', electrode_indices);

**Inconsistent Units or Timestamps:**

.. code-block:: MATLAB

    function validate_temporal_consistency(nwb)
        % Check that all time series use consistent time base
        
        timeseries_objects = find_all_timeseries(nwb);
        reference_time = nwb.timestamps_reference_time;
        
        for ts = timeseries_objects
            if ~isempty(ts.starting_time)
                % Check starting time is reasonable
                if ts.starting_time < 0
                    warning('Negative starting time detected: %.3f', ts.starting_time);
                end
            end
            
            if ~isempty(ts.timestamps)
                % Check timestamp consistency
                timestamps = ts.timestamps.load();
                if any(diff(timestamps) <= 0)
                    warning('Non-monotonic timestamps detected');
                end
            end
        end
    end

Data Type and Format Issues
---------------------------

**Complex Number Handling:**

.. code-block:: text

    Error: Complex data types not supported in NWB files

*Problem:* Trying to store complex-valued data directly.

*Solution:* Split into real and imaginary parts:

.. code-block:: MATLAB

    % Problem: Complex data
    % complex_data = fft(signal);  % Results in complex numbers
    
    % Solution: Store real and imaginary separately
    fft_result = fft(signal);
    real_part = real(fft_result);
    imag_part = imag(fft_result);

    % Store as separate time series
    nwb.processing.get('spectral_analysis').nwbdatainterface.set('fft_real', ...
        create_timeseries(real_part, 'Real part of FFT'));
    nwb.processing.get('spectral_analysis').nwbdatainterface.set('fft_imag', ...
        create_timeseries(imag_part, 'Imaginary part of FFT'));

**String and Text Data:**

.. code-block:: MATLAB

    % Ensure text data is properly formatted
    if iscell(text_data)
        % Convert cell array to character array if needed
        text_data = char(text_data);
    end
    
    % Handle special characters
    text_data = strrep(text_data, char(0), '');  % Remove null characters

Debugging Workflow
------------------

**Step-by-Step Debugging:**

1. **Test with minimal data:**

.. code-block:: MATLAB

    function debug_nwb_creation()
        % Start with absolute minimum
        nwb = NwbFile( ...
            'session_start_time', datetime('now', 'TimeZone', 'local'), ...
            'identifier', 'debug_test', ...
            'session_description', 'Debugging test');
        
        % Export and test
        nwbExport(nwb, 'debug_minimal.nwb');
        test_nwb = nwbRead('debug_minimal.nwb');
        
        % Add components one by one
        nwb.acquisition.set('test_data', create_minimal_timeseries());
        nwbExport(nwb, 'debug_with_data.nwb');
        
        % Continue adding complexity until error occurs
    end

2. **Use verbose error reporting:**

.. code-block:: MATLAB

    try
        nwbExport(nwb, filename);
    catch ME
        fprintf('Error during export:\n');
        fprintf('Message: %s\n', ME.message);
        fprintf('Stack trace:\n');
        for i = 1:length(ME.stack)
            fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
        end
        
        % Try to get more specific information
        if contains(ME.message, 'HDF5')
            fprintf('This appears to be an HDF5-related error\n');
            fprintf('Consider checking data types and file permissions\n');
        end
    end

**Diagnostic Tools:**

.. code-block:: MATLAB

    function diagnose_nwb_problems(nwb)
        % Comprehensive diagnostic function
        
        fprintf('=== NWB Diagnostic Report ===\n');
        
        % Check required fields
        required_fields = {'session_start_time', 'identifier', 'session_description'};
        for field = required_fields
            if isempty(nwb.(field{1}))
                fprintf('ERROR: Required field %s is empty\n', field{1});
            else
                fprintf('OK: %s = %s\n', field{1}, string(nwb.(field{1})));
            end
        end
        
        % Check data sizes
        acquisition_keys = nwb.acquisition.keys();
        for key = acquisition_keys
            data_obj = nwb.acquisition.get(key{1});
            if isprop(data_obj, 'data')
                data_size = size(data_obj.data);
                fprintf('Data object %s: size = [%s]\n', key{1}, ...
                    strjoin(string(data_size), ' x '));
                
                % Check for suspicious sizes
                if any(data_size == 0)
                    fprintf('WARNING: Zero-sized dimension in %s\n', key{1});
                end
            end
        end
        
        % Memory usage estimate
        memory_estimate = estimate_nwb_memory_usage(nwb);
        fprintf('Estimated memory usage: %.2f MB\n', memory_estimate / 1e6);
    end

Getting Help
------------

**When to Seek Help:**

- Error messages that aren't covered in this guide
- Performance issues that persist after optimization  
- File corruption that can't be recovered
- Schema validation errors with unclear causes

**Where to Get Help:**

1. **MatNWB GitHub Issues:** https://github.com/NeurodataWithoutBorders/matnwb/issues
2. **NWB Community Forum:** https://community.nwb.org/
3. **NWB Documentation:** https://nwb-overview.readthedocs.io/

**Information to Include When Reporting Issues:**

.. code-block:: MATLAB

    function create_bug_report()
        % Gather diagnostic information for bug reports
        
        fprintf('=== Bug Report Information ===\n');
        fprintf('MATLAB Version: %s\n', version);
        fprintf('Operating System: %s\n', computer);
        fprintf('MatNWB Version: %s\n', get_matnwb_version());
        
        % Memory information
        if ispc
            [~, mem_info] = system('wmic computersystem get TotalPhysicalMemory /value');
        else
            [~, mem_info] = system('free -h');
        end
        fprintf('Memory Info: %s\n', mem_info);
        
        % Recent errors
        fprintf('Recent errors in command window:\n');
        % Include error messages and stack traces
        
        fprintf('Data characteristics:\n');
        fprintf('  - Dataset sizes: [describe your data dimensions]\n');
        fprintf('  - Data types: [list data types you are using]\n');
        fprintf('  - Processing workflow: [describe your workflow]\n');
    end

This troubleshooting guide should help you resolve most common issues. Remember that many problems can be prevented by following the best practices outlined in previous sections, particularly around HDF5 limitations and performance optimization.
