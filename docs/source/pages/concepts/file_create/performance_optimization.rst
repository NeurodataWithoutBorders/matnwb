Performance Optimization
========================

Creating efficient NWB files requires careful consideration of data layout, compression, and memory usage. This section provides strategies for optimizing performance when working with large datasets.

Understanding DataPipe
-----------------------

The :class:`types.untyped.DataPipe` class is the key to efficient data handling in MatNWB. It provides:

- **Compression** - Reduces file size significantly  
- **Chunking** - Optimizes access patterns
- **Pre-allocation** - Reserve space for datasets that will grow over time
- **Iterative writing** - Enables processing datasets larger than RAM
- **Lazy loading** - Data isn't loaded into memory until needed


Basic DataPipe Usage
~~~~~~~~~~~~~~~~~~~~

.. code-block:: MATLAB

    % Simple compression
    raw_data = randn(10000, 64);  % 10k samples, 64 channels
    
    compressed_data = types.untyped.DataPipe( ...
        'data', raw_data, ...
        'compressionLevel', 6);  % Moderate compression
    
    electrical_series = types.core.ElectricalSeries( ...
        'data', compressed_data, ...
        'electrodes', electrode_region, ...
        'starting_time', 0.0, ...
        'starting_time_rate', 30000.0);

Compression Strategies
----------------------

**Choosing Compression Levels:**

.. code-block:: MATLAB

    % Compression level 0: No compression (fastest, largest files)
    no_compression = types.untyped.DataPipe('data', data, 'compressionLevel', 0);
    
    % Compression level 3-6: Good balance (recommended for most cases)
    balanced = types.untyped.DataPipe('data', data, 'compressionLevel', 4);
    
    % Compression level 9: Maximum compression (slowest, smallest files)
    max_compression = types.untyped.DataPipe('data', data, 'compressionLevel', 9);

**Performance Comparison:**

.. code-block:: MATLAB

    % Benchmark different compression levels
    test_data = uint16(randn(1000, 1000) * 1000 + 2000);  % Typical imaging data
    
    for comp_level = [0, 3, 6, 9]
        tic;
        data_pipe = types.untyped.DataPipe( ...
            'data', test_data, ...
            'compressionLevel', comp_level);
        
        nwb = create_test_nwb();
        nwb.acquisition.set('test_data', create_timeseries(data_pipe));
        filename = sprintf('test_compression_%d.nwb', comp_level);
        nwbExport(nwb, filename);
        
        file_info = dir(filename);
        time_taken = toc;
        
        fprintf('Compression %d: %.2f seconds, %.2f MB\n', ...
            comp_level, time_taken, file_info.bytes / 1e6);
        delete(filename);
    end

Optimal Chunking
----------------

Chunking determines how data is stored internally and dramatically affects access performance:

**Time-Series Chunking:**

.. code-block:: MATLAB

    data = randn(100000, 32);  % 100k timepoints, 32 channels
    
    % For temporal analysis (accessing time ranges):
    temporal_chunks = types.untyped.DataPipe( ...
        'data', data, ...
        'chunkSize', [1000, 32]);  % 1k timepoints, all channels
    
    % For channel analysis (accessing individual channels):
    channel_chunks = types.untyped.DataPipe( ...
        'data', data, ...
        'chunkSize', [100000, 1]);  % All timepoints, single channel
    
    % For block analysis (accessing small time-channel blocks):
    block_chunks = types.untyped.DataPipe( ...
        'data', data, ...
        'chunkSize', [1000, 8]);  % 1k timepoints, 8 channels

**Imaging Data Chunking:**

.. code-block:: MATLAB

    imaging_data = uint16(randn(512, 512, 1000) * 1000);  % 512x512 pixels, 1000 frames
    
    % For frame-by-frame access:
    frame_chunks = types.untyped.DataPipe( ...
        'data', imaging_data, ...
        'chunkSize', [512, 512, 1]);  % One complete frame per chunk
    
    % For pixel time-series analysis:
    pixel_chunks = types.untyped.DataPipe( ...
        'data', imaging_data, ...
        'chunkSize', [1, 1, 1000]);  % All timepoints for single pixel
    
    % For ROI-based access:
    roi_chunks = types.untyped.DataPipe( ...
        'data', imaging_data, ...
        'chunkSize', [64, 64, 100]);  % 64x64 spatial blocks, 100 frames

Automatic Chunk Size Selection
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Let DataPipe choose optimal chunk sizes when you're unsure:

.. code-block:: MATLAB

    % DataPipe will automatically choose reasonable chunk size
    auto_chunked = types.untyped.DataPipe( ...
        'data', data, ...
        'compressionLevel', 6);  % Only specify compression
    
    % You can still provide hints about the primary access dimension
    time_optimized = types.untyped.DataPipe( ...
        'data', data, ...
        'axis', 1);  % Hint: will primarily access along first dimension (time)

Memory-Efficient Large Dataset Handling
---------------------------------------

**Iterative Writing Workflow:**

For datasets larger than available RAM:

.. code-block:: MATLAB

    function create_large_nwb_file(total_duration_sec, sampling_rate, num_channels)
        % Calculate dimensions
        total_samples = total_duration_sec * sampling_rate;
        chunk_duration = 60;  % Process 1 minute at a time
        chunk_samples = chunk_duration * sampling_rate;
        
        % Create initial chunk
        first_chunk = load_data_chunk(1, chunk_samples, num_channels);
        
        % Create DataPipe with reserved space
        data_pipe = types.untyped.DataPipe( ...
            'data', first_chunk, ...
            'maxSize', [total_samples, num_channels], ...
            'chunkSize', [chunk_samples, num_channels], ...
            'compressionLevel', 6, ...
            'axis', 1);
        
        % Create NWB file
        nwb = create_base_nwb();
        electrical_series = types.core.ElectricalSeries( ...
            'data', data_pipe, ...
            'electrodes', electrode_region, ...
            'starting_time', 0.0, ...
            'starting_time_rate', sampling_rate);
        
        nwb.acquisition.set('continuous_ephys', electrical_series);
        nwbExport(nwb, 'large_dataset.nwb');
        
        % Append remaining chunks
        nwb = nwbRead('large_dataset.nwb', 'ignorecache');
        num_chunks = ceil(total_samples / chunk_samples);
        
        for chunk_idx = 2:num_chunks
            fprintf('Processing chunk %d of %d\n', chunk_idx, num_chunks);
            
            % Load next chunk from your data source
            chunk_data = load_data_chunk(chunk_idx, chunk_samples, num_channels);
            
            % Append to file
            nwb.acquisition.get('continuous_ephys').data.append(chunk_data);
        end
        
        fprintf('Large dataset creation complete!\n');
    end

**Streaming from Acquisition Systems:**

.. code-block:: MATLAB

    function stream_acquisition_to_nwb(acquisition_system, output_file)
        % Initialize with small buffer
        buffer_size = 30000;  % 1 second at 30kHz
        initial_data = zeros(buffer_size, 32);
        
        data_pipe = types.untyped.DataPipe( ...
            'data', initial_data, ...
            'maxSize', [Inf, 32], ...  % Unknown final size
            'chunkSize', [buffer_size, 32]);
        
        % Create and export initial NWB structure
        nwb = create_acquisition_nwb();
        nwb.acquisition.set('live_recording', ...
            create_electrical_series(data_pipe));
        nwbExport(nwb, output_file);
        
        % Stream data as it arrives
        nwb = nwbRead(output_file, 'ignorecache');
        
        while acquisition_system.is_recording()
            new_data = acquisition_system.get_next_buffer();
            nwb.acquisition.get('live_recording').data.append(new_data);
        end
    end

Optimizing Data Types
---------------------

**Choose Appropriate Numeric Types:**

.. code-block:: MATLAB

    % Raw electrophysiology: often int16 is sufficient
    raw_ephys = int16(randn(10000, 32) * 1000);  % ±32,767 range
    
    % Calcium imaging: uint16 typical for camera data
    calcium_data = uint16(randn(512, 512, 1000) * 1000 + 2000);
    
    % Processed data: may need double precision
    processed_signals = double(compute_filtered_signals(raw_ephys));
    
    % Behavioral measurements: single precision often sufficient
    position_data = single(randn(10000, 2));

**Memory Usage Comparison:**

.. code-block:: MATLAB

    % Compare memory usage of different data types
    n_samples = 1000000;
    
    double_data = randn(n_samples, 1);           % 8 bytes per sample
    single_data = single(randn(n_samples, 1));   % 4 bytes per sample  
    int16_data = int16(randn(n_samples, 1)*1000); % 2 bytes per sample
    
    fprintf('Double: %.1f MB\n', whos('double_data').bytes / 1e6);
    fprintf('Single: %.1f MB\n', whos('single_data').bytes / 1e6);
    fprintf('Int16:  %.1f MB\n', whos('int16_data').bytes / 1e6);

Parallel Processing Considerations
----------------------------------

**File-Level Parallelization:**

Process different experimental sessions in parallel:

.. code-block:: MATLAB

    session_files = {'session1.mat', 'session2.mat', 'session3.mat'};
    
    parfor i = 1:length(session_files)
        % Each worker creates its own NWB file
        session_data = load(session_files{i});
        nwb = convert_session_to_nwb(session_data);
        
        output_file = sprintf('session_%03d.nwb', i);
        nwbExport(nwb, output_file);
    end

**Data-Level Parallelization:**

Process large datasets in parallel chunks:

.. code-block:: MATLAB

    function process_large_dataset_parallel(input_file, output_file)
        % Load metadata to determine processing strategy
        data_info = get_dataset_info(input_file);
        num_chunks = ceil(data_info.total_samples / data_info.chunk_size);
        
        % Process chunks in parallel
        processed_chunks = cell(num_chunks, 1);
        
        parfor chunk_idx = 1:num_chunks
            raw_chunk = load_data_chunk(input_file, chunk_idx);
            processed_chunks{chunk_idx} = process_chunk(raw_chunk);
        end
        
        % Combine results sequentially (HDF5 doesn't support parallel writing)
        combine_chunks_to_nwb(processed_chunks, output_file);
    end

Performance Monitoring
----------------------

**Benchmark Your Workflow:**

.. code-block:: MATLAB

    function benchmark_nwb_creation(data_sizes, chunk_sizes, compression_levels)
        results = table();
        
        for data_size = data_sizes
            for chunk_size = chunk_sizes
                for comp_level = compression_levels
                    % Generate test data
                    test_data = randn(data_size, 32);
                    
                    % Time the creation process
                    tic;
                    data_pipe = types.untyped.DataPipe( ...
                        'data', test_data, ...
                        'chunkSize', [chunk_size, 32], ...
                        'compressionLevel', comp_level);
                    
                    nwb = create_test_nwb();
                    nwb.acquisition.set('test', create_timeseries(data_pipe));
                    
                    filename = 'benchmark_temp.nwb';
                    nwbExport(nwb, filename);
                    creation_time = toc;
                    
                    % Measure file size
                    file_info = dir(filename);
                    file_size_mb = file_info.bytes / 1e6;
                    
                    % Test read performance
                    tic;
                    test_nwb = nwbRead(filename);
                    sample_data = test_nwb.acquisition.get('test').data.load(1:1000, :);
                    read_time = toc;
                    
                    % Store results
                    new_row = table(data_size, chunk_size, comp_level, ...
                        creation_time, file_size_mb, read_time, ...
                        'VariableNames', {'DataSize', 'ChunkSize', 'CompressionLevel', ...
                        'CreationTime', 'FileSizeMB', 'ReadTime'});
                    results = [results; new_row];
                    
                    delete(filename);
                end
            end
        end
        
        % Display results
        disp(results);
        
        % Plot performance trends
        figure;
        scatter3(results.DataSize, results.CompressionLevel, results.CreationTime);
        xlabel('Data Size'); ylabel('Compression Level'); zlabel('Creation Time (s)');
        title('NWB Creation Performance');
    end

Best Practices Summary
----------------------

1. **Use DataPipe for all large datasets** (> 100 MB)
2. **Choose compression level 4-6** for most applications
3. **Align chunk sizes with your analysis patterns**
4. **Use appropriate numeric data types** to minimize memory usage
5. **Process in parallel at the file level**, not within files
6. **Benchmark your specific workflow** to identify bottlenecks
7. **Pre-allocate space** for datasets that will grow over time

.. code-block:: MATLAB

    % Template for high-performance NWB creation
    function create_optimized_nwb(raw_data_source, output_file)
        % Determine optimal parameters for your data
        data_info = analyze_data_characteristics(raw_data_source);
        
        optimal_chunk_size = calculate_optimal_chunks(data_info);
        compression_level = 6;  % Good default
        
        % Create DataPipe with optimized settings
        data_pipe = types.untyped.DataPipe( ...
            'compressionLevel', compression_level, ...
            'chunkSize', optimal_chunk_size);
        
        % Build NWB structure efficiently
        nwb = build_nwb_structure_fast();
        
        % Add data and export
        add_data_efficiently(nwb, data_pipe, raw_data_source);
        nwbExport(nwb, output_file);
        
        % Validate performance
        validate_file_performance(output_file);
    end
