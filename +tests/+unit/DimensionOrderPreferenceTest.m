classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
    DimensionOrderPreferenceTest < matlab.unittest.TestCase
%DIMENSIONORDERPREFERENCETEST Unit tests for the DimensionOrder preference.
%
%   Tests verify that:
%   - The preference system correctly stores and retrieves the active mode
%   - shouldFlipDimensions() returns the correct value for each mode
%   - Reading and writing NWB data produces the correct dimension ordering
%     for both matlab_style and schema_style modes
%   - DataPipe operations respect the active mode
%   - Cross-mode round-trips preserve data integrity

    methods (TestMethodSetup)
        function setupMethod(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            originalMode = matnwb.preference.DimensionOrder.getMode();
            testCase.addTeardown(@() restoreMode(originalMode));
        end
    end

    %% Preference system tests
    methods (Test)
        function testDefaultModeIsMatlabStyle(testCase)
            matnwb.preference.DimensionOrder.resetCache();
            rmpref('matnwb', 'DimensionOrderMode');
            matnwb.preference.DimensionOrder.resetCache();
            actualMode = matnwb.preference.DimensionOrder.getMode();
            testCase.verifyEqual(actualMode, ...
                matnwb.preference.DimensionOrderMode.matlab_style, ...
                'Default mode should be matlab_style for backward compatibility.');
        end

        function testSetAndGetModeWithEnum(testCase)
            matnwb.preference.DimensionOrder.setMode( ...
                matnwb.preference.DimensionOrderMode.schema_style);
            actualMode = matnwb.preference.DimensionOrder.getMode();
            testCase.verifyEqual(actualMode, ...
                matnwb.preference.DimensionOrderMode.schema_style);

            matnwb.preference.DimensionOrder.setMode( ...
                matnwb.preference.DimensionOrderMode.matlab_style);
            actualMode = matnwb.preference.DimensionOrder.getMode();
            testCase.verifyEqual(actualMode, ...
                matnwb.preference.DimensionOrderMode.matlab_style);
        end

        function testSetAndGetModeWithString(testCase)
            matnwb.preference.DimensionOrder.setMode('schema_style');
            actualMode = matnwb.preference.DimensionOrder.getMode();
            testCase.verifyEqual(actualMode, ...
                matnwb.preference.DimensionOrderMode.schema_style);
        end

        function testSetModeRejectsInvalidInput(testCase)
            testCase.verifyError( ...
                @() matnwb.preference.DimensionOrder.setMode('invalid_mode'), ...
                'NWB:Preference:DimensionOrder:InvalidMode');
        end

        function testShouldFlipDimensionsMatlabStyle(testCase)
            matnwb.preference.DimensionOrder.setMode('matlab_style');
            testCase.verifyTrue(matnwb.preference.shouldFlipDimensions(), ...
                'shouldFlipDimensions() should return true in matlab_style mode.');
        end

        function testShouldFlipDimensionsSchemaStyle(testCase)
            matnwb.preference.DimensionOrder.setMode('schema_style');
            testCase.verifyFalse(matnwb.preference.shouldFlipDimensions(), ...
                'shouldFlipDimensions() should return false in schema_style mode.');
        end

        function testConvenienceFunctionMatchesStaticMethod(testCase)
            matnwb.preference.DimensionOrder.setMode('matlab_style');
            testCase.verifyEqual( ...
                matnwb.preference.shouldFlipDimensions(), ...
                matnwb.preference.DimensionOrder.shouldFlipDimensions());

            matnwb.preference.DimensionOrder.setMode('schema_style');
            testCase.verifyEqual( ...
                matnwb.preference.shouldFlipDimensions(), ...
                matnwb.preference.DimensionOrder.shouldFlipDimensions());
        end

        function testResetCacheForcesReread(testCase)
            matnwb.preference.DimensionOrder.setMode('schema_style');
            matnwb.preference.DimensionOrder.resetCache();
            % After cache reset the preference is re-read from setpref storage
            actualMode = matnwb.preference.DimensionOrder.getMode();
            testCase.verifyEqual(actualMode, ...
                matnwb.preference.DimensionOrderMode.schema_style, ...
                'Mode should still be schema_style after cache reset.');
        end
    end

    %% NWB round-trip tests
    methods (Test)
        function testRoundTripMatlabStyle(testCase)
        % Write and read a multi-dimensional dataset in matlab_style mode.
        % The data should come back with the same MATLAB dimension ordering.
            matnwb.preference.DimensionOrder.setMode('matlab_style');
            filename = 'roundtrip_matlab_style.nwb';

            % 5 samples x 3 channels x 10 timepoints (MATLAB order)
            originalData = reshape(1:150, 5, 3, 10);

            nwbFile = tests.factory.NWBFile();
            timeSeries = types.core.TimeSeries( ...
                'starting_time', 0.0, ...
                'starting_time_rate', 30.0, ...
                'data', originalData, ...
                'data_unit', 'n/a');
            nwbFile.acquisition.set('ts', timeSeries);
            nwbExport(nwbFile, filename);

            readNwb = nwbRead(filename, 'ignorecache');
            readData = readNwb.acquisition.get('ts').data.load();

            testCase.verifyEqual(readData, originalData, ...
                'Round-trip in matlab_style should preserve MATLAB dimension order.');
        end

        function testRoundTripSchemaStyle(testCase)
        % Write and read a multi-dimensional dataset in schema_style mode.
        % In schema_style the user supplies and receives data in HDF5/schema
        % dimension order (slowest-changing dimension first).
            matnwb.preference.DimensionOrder.setMode('schema_style');
            filename = 'roundtrip_schema_style.nwb';

            % 10 timepoints x 3 channels x 5 samples (schema/HDF5 order)
            originalData = reshape(1:150, 10, 3, 5);

            nwbFile = tests.factory.NWBFile();
            timeSeries = types.core.TimeSeries( ...
                'starting_time', 0.0, ...
                'starting_time_rate', 30.0, ...
                'data', originalData, ...
                'data_unit', 'n/a');
            nwbFile.acquisition.set('ts', timeSeries);
            nwbExport(nwbFile, filename);

            readNwb = nwbRead(filename, 'ignorecache');
            readData = readNwb.acquisition.get('ts').data.load();

            testCase.verifyEqual(readData, originalData, ...
                'Round-trip in schema_style should preserve schema dimension order.');
        end

        function testDimensionsAreReversedBetweenModes(testCase)
        % The same numeric data written in matlab_style should appear with
        % reversed dimensions when read back in schema_style.
            matlabFilename = 'data_matlab_style.nwb';
            schemaFilename = 'data_schema_style.nwb';

            % 4 x 3 x 2 data in MATLAB order
            matlabOrderData = reshape(1:24, 4, 3, 2);

            matnwb.preference.DimensionOrder.setMode('matlab_style');
            nwbMatlabStyle = tests.factory.NWBFile();
            tsMatlabStyle = types.core.TimeSeries( ...
                'starting_time', 0.0, ...
                'starting_time_rate', 30.0, ...
                'data', matlabOrderData, ...
                'data_unit', 'n/a');
            nwbMatlabStyle.acquisition.set('ts', tsMatlabStyle);
            nwbExport(nwbMatlabStyle, matlabFilename);

            % Read the same file in schema_style — dimensions should be reversed
            matnwb.preference.DimensionOrder.setMode('schema_style');
            readNwb = nwbRead(matlabFilename, 'ignorecache');
            readData = readNwb.acquisition.get('ts').data.load();

            expectedSchemaData = permute(matlabOrderData, [3, 2, 1]);
            testCase.verifyEqual(readData, expectedSchemaData, ...
                'Data written in matlab_style should appear with reversed dimensions in schema_style.');
        end
    end

    %% DataPipe tests
    methods (Test)
        function testDataPipeAppendMatlabStyle(testCase)
        % Verify DataPipe append works correctly in matlab_style mode.
            matnwb.preference.DimensionOrder.setMode('matlab_style');
            filename = 'pipe_matlab_style.h5';
            datasetPath = '/test_data';

            % 3 channels, extendable along time (axis 2 in MATLAB order)
            maxSize = [3, Inf];
            chunkSize = [3, 10];
            initialData = ones(3, 10);
            appendedData = 2 * ones(3, 5);

            pipe = types.untyped.DataPipe( ...
                'data', initialData, ...
                'maxSize', maxSize, ...
                'chunkSize', chunkSize, ...
                'axis', 2);

            fid = H5F.create(filename);
            pipe.export(fid, datasetPath, {});
            H5F.close(fid);

            pipe2 = types.untyped.DataPipe('filename', filename, 'path', datasetPath);
            pipe2.append(appendedData);

            loadedData = h5read(filename, datasetPath);
            % h5read returns in MATLAB (flipped) order, so we compare directly
            expectedData = [initialData, appendedData];
            testCase.verifyEqual(loadedData, expectedData, ...
                'DataPipe append in matlab_style should produce correct data.');
        end

        function testDataPipeAppendSchemaStyle(testCase)
        % Verify DataPipe append works correctly in schema_style mode.
        % In schema_style, time is axis 1 (slowest-changing, schema order).
            matnwb.preference.DimensionOrder.setMode('schema_style');
            filename = 'pipe_schema_style.h5';
            datasetPath = '/test_data';

            % In schema_style: time x channels
            % Extendable along axis 1 (time, slowest-changing in schema order)
            maxSize = [Inf, 3];
            chunkSize = [10, 3];
            initialData = ones(10, 3);
            appendedData = 2 * ones(5, 3);

            pipe = types.untyped.DataPipe( ...
                'data', initialData, ...
                'maxSize', maxSize, ...
                'chunkSize', chunkSize, ...
                'axis', 1);

            fid = H5F.create(filename);
            pipe.export(fid, datasetPath, {});
            H5F.close(fid);

            pipe2 = types.untyped.DataPipe('filename', filename, 'path', datasetPath);
            pipe2.append(appendedData);

            loadedData = h5read(filename, datasetPath);
            % h5read returns in MATLAB (column-major flipped) order, so
            % for an HDF5 layout of [time x channels] this comes back as
            % [channels x time] — flip to compare with schema-order expected
            expectedSchemaData = [initialData; appendedData];
            testCase.verifyEqual(loadedData.', expectedSchemaData, ...
                'DataPipe append in schema_style should produce correct data.');
        end
    end
end

%% Helpers
function restoreMode(mode)
    matnwb.preference.DimensionOrder.setMode(mode);
end
