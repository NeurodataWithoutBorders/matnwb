classdef createIndexedColumnTest < tests.abstract.NwbTestCase
% createIndexedColumnTest - Unit tests for util.create_indexed_column

    methods (TestClassSetup)
        function setupClass(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testRowVectors(testCase)
            [vector, index] = util.create_indexed_column({[1 2 3], [4 5]}, 'spike times');

            testCase.verifyEqual(vector.data, [1; 2; 3; 4; 5]);
            testCase.verifyEqual(index.data, uint64([3; 5]));
            testCase.verifyEqual(vector.description, 'spike times');
            testCase.verifySameHandle(index.target.target, vector);
        end

        function testStringRowsKeepTheirClass(testCase)
            [vector, index] = util.create_indexed_column({["a" "b"], "c"});

            testCase.verifyEqual(vector.data, ["a"; "b"; "c"]);
            testCase.verifyEqual(index.data, uint64([2; 3]));
        end

        function testCharRowsAreListsOfCharacters(testCase)
            [vector, index] = util.create_indexed_column({'abc', 'de'});

            testCase.verifyEqual(vector.data, ('abcde')');
            testCase.verifyEqual(index.data, uint64([3; 5]));
        end

        function testStructArrayRowsKeepTheirClass(testCase)
            s1 = struct('x', {uint32(1), uint32(2)}, 'weight', {single(1), single(1)});
            s2 = struct('weight', single(0.5), 'x', uint32(7));   % fields in another order

            [vector, index] = util.create_indexed_column({s1, s2});

            testCase.verifyEqual(vector.data, [s1(:); orderfields(s2, s1)]);
            testCase.verifyEqual(index.data, uint64([2; 3]));
        end

        function testMixedRowTypesErrors(testCase)
            testCase.verifyError(@() util.create_indexed_column({[1 2], "a"}), ...
                'NWB:CreateIndexedColumn:InconsistentElementType');
            % Rows of different numeric classes would convert values silently
            % (3.5 would become int32(4)), so they are rejected.
            testCase.verifyError(@() util.create_indexed_column({int32([1 2]), 3.5}), ...
                'NWB:CreateIndexedColumn:InconsistentElementType');
            testCase.verifyError( ...
                @() util.create_indexed_column({struct('x', 1), struct('y', 2)}), ...
                'NWB:CreateIndexedColumn:InconsistentElementShape');
        end

        function testObjectViewRowsKeepTheirClass(testCase)
            % Rows of object references, with [] for a row that references
            % nothing, as when linking each trial to its raw data.
            seriesView = types.untyped.ObjectView(types.core.TimeSeries('description', 'raw'));
            deviceView = types.untyped.ObjectView(types.core.Device());

            [vector, index] = util.create_indexed_column( ...
                {seriesView, [], [seriesView; deviceView]});

            testCase.verifyEqual(vector.data, [seriesView; seriesView; deviceView]);
            testCase.verifyEqual(index.data, uint64([1; 1; 3]));
        end

        function testObjectRowsMustShareAClassAndBeVectors(testCase)
            seriesView = types.untyped.ObjectView(types.core.TimeSeries('description', 'raw'));
            timestamp = datetime(2024, 1, 1);

            testCase.verifyError(@() util.create_indexed_column({seriesView, timestamp}), ...
                'NWB:CreateIndexedColumn:InconsistentElementType');
            testCase.verifyError(@() util.create_indexed_column({seriesView, [1 2]}), ...
                'NWB:CreateIndexedColumn:InconsistentElementType');
            testCase.verifyError(@() util.create_indexed_column({repmat(seriesView, 2, 2)}), ...
                'NWB:CreateIndexedColumn:InvalidRow');
        end

        function testIntegerRowsKeepTheirClass(testCase)
            [vector, index] = util.create_indexed_column({int32([1 2]), int32(3)});

            testCase.verifyEqual(vector.data, int32([1; 2; 3]));
            testCase.verifyEqual(index.data, uint64([2; 3]));
        end

        function testRowsOfDifferentNumericClassesError(testCase)
            % Rows of different numeric classes would convert values silently
            % (3.5 would become int32(4)), so they are rejected at every depth.
            testCase.verifyError(@() util.create_indexed_column({int32([1 2]), 3.5}), ...
                'NWB:CreateIndexedColumn:InconsistentElementType');
            testCase.verifyError( ...
                @() util.create_indexed_column({{int32([1 2])}, {3.5}}, 'Depth', 2), ...
                'NWB:CreateIndexedColumn:InconsistentElementType');
        end

        function testColumnVectorsMatchRowVectors(testCase)
            % Orientation of a vector row does not matter: both are lists of scalars.
            [fromRows, indexFromRows] = util.create_indexed_column({[1 2 3], [4 5]});
            [fromColumns, indexFromColumns] = util.create_indexed_column({[1; 2; 3], [4; 5]});

            testCase.verifyEqual(fromColumns.data, fromRows.data);
            testCase.verifyEqual(indexFromColumns.data, indexFromRows.data);
        end

        function testEmptyRow(testCase)
            [vector, index] = util.create_indexed_column({[1 2], [], 3});

            testCase.verifyEqual(vector.data, [1; 2; 3]);
            % The empty row repeats the previous cumulative count.
            testCase.verifyEqual(index.data, uint64([2; 2; 3]));
        end

        function testEmptyArrayRowOfAnySizeHasNoElements(testCase)
            % An empty row holds no elements whatever its size: it neither
            % sets the element shape nor has to match it.
            row1 = reshape(1:8, 4, 2);
            row2 = 100 + reshape(1:12, 4, 3);

            [vector, index] = util.create_indexed_column({row1, row2, zeros(4, 3, 0)});
            testCase.verifyEqual(vector.data, [row1, row2]);
            testCase.verifyEqual(index.data, uint64([2; 5; 5]));

            [vector, index] = util.create_indexed_column({zeros(7, 0), row1, zeros(0, 3)});
            testCase.verifyEqual(vector.data, row1);
            testCase.verifyEqual(index.data, uint64([0; 2; 2]));
        end

        function testMatrixRows(testCase)
            % Elements are 4-sample vectors, one per column, as in VectorData.data.
            row1 = reshape(1:8, 4, 2);          % 2 elements
            row2 = 100 + reshape(1:12, 4, 3);   % 3 elements

            [vector, index] = util.create_indexed_column({row1, row2});

            testCase.verifyEqual(size(vector.data), [4, 5]);
            testCase.verifyEqual(vector.data(:, 1:2), row1);
            testCase.verifyEqual(vector.data(:, 3:5), row2);
            testCase.verifyEqual(index.data, uint64([2; 5]));
        end

        function testNDRows(testCase)
            % HDMF's DynamicTable.add_row stores the rows (2,3,4) and (1,3,4) of
            % an indexed column as data (3,3,4) with index [2 3] (hdmf 6.2.0).
            % With the ragged axis last, the MatNWB rows are [4x3x2] and [4x3x1],
            % and the data is [4x3x3], which is (3,3,4) on disk.
            row1 = reshape(1:24, 4, 3, 2);
            row2 = 100 + reshape(1:12, 4, 3);   % one element; MATLAB drops the trailing 1

            [vector, index] = util.create_indexed_column({row1, row2});

            testCase.verifyEqual(size(vector.data), [4, 3, 3]);
            testCase.verifyEqual(vector.data(:, :, 1:2), row1);
            testCase.verifyEqual(vector.data(:, :, 3), row2);
            testCase.verifyEqual(index.data, uint64([2; 3]));
        end

        function testSingleElementColumnVectorAmongMatrixRows(testCase)
            row1 = reshape(1:8, 4, 2);
            row2 = (101:104)';   % one 4-sample element

            [vector, index] = util.create_indexed_column({row1, row2});

            testCase.verifyEqual(vector.data(:, 3), row2);
            testCase.verifyEqual(index.data, uint64([2; 3]));
        end

        function testSingleElementRowInAnyOrder(testCase)
            % Elements [4 x 3]: the single-element row [4 x 3] is read the same
            % whether or not a fuller row precedes it.
            oneElement = reshape(1:12, 4, 3);
            twoElements = 100 + reshape(1:24, 4, 3, 2);

            [vector, index] = util.create_indexed_column({oneElement, twoElements});

            testCase.verifyEqual(size(vector.data), [4, 3, 3]);
            testCase.verifyEqual(vector.data(:, :, 1), oneElement);
            testCase.verifyEqual(index.data, uint64([1; 3]));

            [vector, index] = util.create_indexed_column({twoElements, oneElement});

            testCase.verifyEqual(vector.data(:, :, 3), oneElement);
            testCase.verifyEqual(index.data, uint64([2; 3]));
        end

        function testInconsistentElementShapeErrors(testCase)
            testCase.verifyError( ...
                @() util.create_indexed_column({ones(4, 2), ones(5, 2)}), ...
                'NWB:CreateIndexedColumn:InconsistentElementShape');
            % A row vector is not one 4-sample element; that is [4 x 1].
            testCase.verifyError( ...
                @() util.create_indexed_column({ones(4, 2), ones(1, 4)}), ...
                'NWB:CreateIndexedColumn:InconsistentElementShape');
        end

        function testInvalidRowTypeErrors(testCase)
            testCase.verifyError( ...
                @() util.create_indexed_column({[1 2], @sin}), ...
                'NWB:CreateIndexedColumn:InvalidRow');
            % Strings, characters and structs are accepted as vectors only.
            testCase.verifyError( ...
                @() util.create_indexed_column({["a" "b"; "c" "d"]}), ...
                'NWB:CreateIndexedColumn:InvalidRow');
        end

        function testTableRegion(testCase)
            target = types.hdmf_common.DynamicTable( ...
                'description', 'target', ...
                'colnames', {'x'}, ...
                'x', types.hdmf_common.VectorData('description', 'x', 'data', (1:5)'), ...
                'id', types.hdmf_common.ElementIdentifiers('data', (0:4)'));

            [region, index] = util.create_indexed_column({[0 1], [2 3 4]}, 'regions', target);

            testCase.verifyClass(region, 'types.hdmf_common.DynamicTableRegion');
            % The region validator casts the row indices to an integer class.
            testCase.verifyEqual(double(region.data), [0; 1; 2; 3; 4]);
            testCase.verifyEqual(index.data, uint64([2; 5]));
        end

        function testDepth2NestedCell(testCase)
            % data{row}{subGroup} = [num_samples x nElements]; the element count
            % may differ between sub-groups.
            numSamples = 4;
            unit1 = {ones(numSamples, 2), 2*ones(numSamples, 1)};   % 2 then 1 electrode
            unit2 = {3*ones(numSamples, 3)};

            [vector, index, indexIndex] = ...
                util.create_indexed_column({unit1, unit2}, 'Depth', 2);

            testCase.verifyEqual(size(vector.data), [numSamples, 6]);
            testCase.verifyEqual(index.data, uint64([2; 3; 6]));
            testCase.verifyEqual(indexIndex.data, uint64([2; 3]));
        end

        function testDepth2NDElements(testCase)
            % Elements with more than one dimension keep their shape; the
            % ragged axis stays last.
            unit1 = {reshape(1:(4*5*2), 4, 5, 2), 100+reshape(1:(4*5), 4, 5)};   % 2 then 1 element
            unit2 = {200+reshape(1:(4*5*3), 4, 5, 3)};

            [vector, index, indexIndex] = ...
                util.create_indexed_column({unit1, unit2}, 'Depth', 2);

            testCase.verifyEqual(size(vector.data), [4, 5, 6]);
            testCase.verifyEqual(vector.data(:, :, 3), unit1{2});
            testCase.verifyEqual(vector.data(:, :, 6), unit2{1}(:, :, 3));
            testCase.verifyEqual(index.data, uint64([2; 3; 6]));
            testCase.verifyEqual(indexIndex.data, uint64([2; 3]));
        end

        function testDepth2EmptyRow(testCase)
            numSamples = 4;
            unit1 = reshape(1:(2*numSamples), numSamples, 2);
            unit3 = reshape(1:(3*numSamples), numSamples, 3);

            [vector, index, indexIndex] = ...
                util.create_indexed_column({{unit1}, [], {unit3}}, 'Depth', 2);

            testCase.verifyEqual(size(vector.data), [numSamples, 5]);
            testCase.verifyEqual(index.data, uint64([2; 5]));
            testCase.verifyEqual(indexIndex.data, uint64([1; 1; 2]));
        end

        function testSingleMultiSampleElementInColumnErrors(testCase)
            % One 40-sample element in the whole column would be stored as
            % a [40 x 1] array, which is written and read as 40 scalars.
            testCase.verifyError( ...
                @() util.create_indexed_column({{ones(40, 1)}, {}}, 'Depth', 2), ...
                'NWB:CreateIndexedColumn:SingleElementColumn');

            % A single element with one value is stored.
            [vector, index, indexIndex] = util.create_indexed_column({{5}}, 'Depth', 2);
            testCase.verifyEqual(vector.data, 5);
            testCase.verifyEqual(index.data, uint64(1));
            testCase.verifyEqual(indexIndex.data, uint64(1));
        end

        function testStringDescriptionIsStoredAsChar(testCase)
            vector = util.create_indexed_column({[1 2]}, "spike times");

            testCase.verifyClass(vector.description, 'char');
            testCase.verifyEqual(vector.description, 'spike times');
        end

        function testTableGivenAsPath(testCase)
            % The table of a region can be given as its path in the file.
            [region, index] = util.create_indexed_column( ...
                {[0 1], 2}, 'regions', '/acquisition/target');

            testCase.verifyClass(region, 'types.hdmf_common.DynamicTableRegion');
            testCase.verifyEqual(region.table.path, '/acquisition/target');
            testCase.verifyEqual(region.description, 'regions');
            testCase.verifyEqual(index.data, uint64([2; 3]));
        end

        function testShapeErrorNamesTheRow(testCase)
            % The sub-group of row 2 has 5-sample elements among 4-sample
            % ones; the error names it.
            try
                util.create_indexed_column({{ones(4, 2)}, {ones(5, 2)}}, 'Depth', 2);
                testCase.verifyFail('Expected an error.');
            catch err
                testCase.verifyEqual(err.identifier, 'NWB:CreateIndexedColumn:InconsistentElementShape');
                testCase.verifySubstring(err.message, 'data{2}{1}');
            end
        end

        function testDepth2Errors(testCase)
            % A row of depth 2 is a cell array of sub-groups, not a numeric array.
            testCase.verifyError( ...
                @() util.create_indexed_column({ones(3, 4), ones(2, 5)}, 'Depth', 2), ...
                'NWB:CreateIndexedColumn:InvalidRow');
            testCase.verifyError( ...
                @() util.create_indexed_column({{ones(4, 2)}, "text"}, 'Depth', 2), ...
                'NWB:CreateIndexedColumn:InvalidRow');
            % A cell nested deeper than Depth is an error.
            testCase.verifyError( ...
                @() util.create_indexed_column({{[1 2 3]}}), ...
                'NWB:CreateIndexedColumn:InvalidRow');
        end

        function testTooManyOutputsErrors(testCase)
            testCase.verifyError(@() requestThreeOutputs({[1 2], 3}), ...
                'NWB:CreateIndexedColumn:TooManyOutputs');
        end

        function testMatrixRowsRoundTrip(testCase)
            % The ragged axis is last in MATLAB, so it is first on disk as the
            % schema requires, and the column survives export and read.
            row1 = reshape(1:8, 4, 2);
            row2 = 100 + reshape(1:12, 4, 3);
            [vector, index] = util.create_indexed_column({row1, row2}, 'waveform-like');

            dynamicTable = types.hdmf_common.DynamicTable('description', 'test');
            dynamicTable.addColumn('wf', vector, 'wf_index', index);
            testCase.verifyEqual(numel(dynamicTable.id.data), 2);

            nwb = NwbFile( ...
                'identifier', 'indexed_column_test', ...
                'session_description', 'test', ...
                'session_start_time', datetime(2024, 1, 1, 'TimeZone', 'local'));
            nwb.acquisition.set('DynamicTable', dynamicTable);

            fileName = testCase.getRandomFilename();
            nwbExport(nwb, fileName);

            testCase.verifyEqual(readOnDiskShape(fileName, '/acquisition/DynamicTable/wf'), [5, 4]);

            back = nwbRead(fileName, 'ignorecache');
            column = back.acquisition.get('DynamicTable').vectordata.get('wf');
            columnIndex = back.acquisition.get('DynamicTable').vectordata.get('wf_index');
            testCase.verifyEqual(column.data.load(), vector.data);
            testCase.verifyEqual(columnIndex.data.load(), uint64([2; 5]));
        end
    end
end

function shape = readOnDiskShape(fileName, datasetPath)
    % C-order shape of a dataset, i.e. the schema's dimension order. h5info
    % reports sizes in MATLAB order, so use the low-level API.
    fileId = H5F.open(fileName, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
    fileCleanup = onCleanup(@() H5F.close(fileId));
    datasetId = H5D.open(fileId, datasetPath);
    datasetCleanup = onCleanup(@() H5D.close(datasetId));
    spaceId = H5D.get_space(datasetId);
    spaceCleanup = onCleanup(@() H5S.close(spaceId));
    [~, shape] = H5S.get_simple_extent_dims(spaceId);
    delete(spaceCleanup)
    delete(datasetCleanup)
    delete(fileCleanup)
end

function requestThreeOutputs(data)
    [~, ~, ~] = util.create_indexed_column(data);
end
