classdef DynamicTableTest < tests.system.RoundTripTest & tests.system.AmendTest
    methods
        function addContainer(~, file)
            colnames = {'start_time', 'stop_time', 'randomvalues', 'stringdata'};
            file.intervals_trials = types.core.TimeIntervals(...
                'description', 'test dynamic table column',...
                'colnames', colnames);
            
            id = primes(2000) .';
            for i = 1:100
                file.intervals_trials.addRow(...
                    'start_time', i,...
                    'stop_time', i+1,...
                    'randomvalues', {rand(5,2);rand(3,2)},...
                    'stringdata', {'TRUE'},...
                    'id', id(i));
            end
            file.intervals_trials.addRow(table(...
                id(101:200),...
                (101:200) .',...
                (102:201) .',...
                mat2cell(rand(500,2), repmat(5, 100, 1)),...
                repmat({'TRUE'}, 100, 1),...
                'VariableNames', {'id', 'start_time', 'stop_time', 'randomvalues', 'stringdata'}));
        end
        
        function addExpandableContainer(~, file, start_array, stop_array, random_array, id_array)
            %create VectorData objects with DataPipe objects
            start_time_exp = types.hdmf_common.VectorData( ...
                'description','start times', ...
                'data', types.untyped.DataPipe( ...
                    'data', start_array', ...
                    'maxSize', [Inf, 1], ...
                    'axis', 1 ...
                ) ...
            );
            stop_time_exp = types.hdmf_common.VectorData( ...
                'description', 'stop times', ...
                'data', types.untyped.DataPipe( ...
                    'data', stop_array', ...
                    'maxSize', [Inf, 1], ...
                    'axis', 1 ...
                ) ...
            );
            random_exp = types.hdmf_common.VectorData( ...
                'description', 'random data column', ...
                'data', types.untyped.DataPipe( ...
                    'data', random_array, ...
                    'maxSize', [Inf, 1], ...
                    'axis', 1 ...
                )...
            );
            ids_exp = types.hdmf_common.ElementIdentifiers( ...
                'data', types.untyped.DataPipe( ...
                    'data', id_array', ... 
                    'maxSize', [Inf, 1], ...
                    'axis', 1 ...
                    ) ...
            );
            %create expandable table
            colnames = {'start_time', 'stop_time', 'randomvalues'};
            file.intervals_trials = types.core.TimeIntervals( ...
                'description', 'test expdandable dynamic table', ...
                'colnames', colnames, ...
                'start_time', start_time_exp, ...
                'stop_time', stop_time_exp, ...
                'randomvalues', random_exp, ...
                'id', ids_exp ...
            );    
        end
        
        function c = getContainer(~, file)
            c = file.intervals_trials.vectordata.get('randomvalues');
        end

        function appendContainer(testCase, file)
            container = testCase.getContainer(file);
            container.data = rand(1300, 2); % new random values.
            file.intervals_trials.vectordata.get('stringdata').data = repmat({'FALSE'}, 200, 1);
            file.intervals_trials.colnames{end+1} = 'newcolumn';
            file.intervals_trials.vectordata.set('newcolumn',...
                types.hdmf_common.VectorData(...
                'description', 'newly added column',...
                'data', 200:-1:1));
        end
    end
    
    methods (Test)
        function getRowTest(testCase)
            Table = testCase.file.intervals_trials;

            BaseVectorData = Table.vectordata.get('randomvalues');
            VectorDataInd = Table.vectordata.get('randomvalues_index');
            VectorDataIndInd = Table.vectordata.get('randomvalues_index_index');

            endInd = VectorDataIndInd.data(5);
            startInd = VectorDataIndInd.data(4) + 1;

            Indices = startInd:endInd;
            dataIndices = cell(length(Indices),1);
            for iRaggedInd = 1:length(Indices)
                endInd = VectorDataInd.data(Indices(iRaggedInd));
                if 1 == Indices(iRaggedInd)
                    startInd = 1;
                else
                    startInd = VectorDataInd.data(Indices(iRaggedInd) - 1) + 1;
                end
                dataIndices{iRaggedInd} = BaseVectorData.data((startInd:endInd) .', :);
            end

            actualData = Table.getRow(5, 'columns', {'randomvalues'});
            testCase.verifyEqual(dataIndices, actualData.randomvalues{1});
        end

        function getRowRoundtripTest(testCase)
            filename = ['MatNWB.' testCase.className() '.testGetRow.nwb'];
            nwbExport(testCase.file, filename);
            ActualFile = nwbRead(filename);
            ActualTable = ActualFile.intervals_trials;
            ExpectedTable = testCase.file.intervals_trials;

            testCase.verifyEqual(ExpectedTable.getRow(5), ActualTable.getRow(5));
            testCase.verifyEqual(ExpectedTable.getRow([5 6]), ActualTable.getRow([5 6]));
            testCase.verifyEqual(ExpectedTable.getRow([1153, 1217], 'useId', true),...
                ActualTable.getRow([1153, 1217], 'useId', true));
        end
        
        function ExpandableTableTest(testCase)
            %define data matrices
            nrows = 200;
            id = 0:nrows-1;%different from row poistion
            start_time_array = 1:nrows;
            stop_time_array = start_time_array + 1;
            rng(1);%to be able replicate random values
            random_val_array = rand(nrows, 1);
            %create expandable table with first half of arrays
            testCase.addExpandableContainer(testCase.file, ...
                start_time_array(1:100), stop_time_array(1:100), ...
                random_val_array(1:100), id(1:100));
            %export and read-in expandable table
            filename = ['MatNWB.' testCase.className() '.ExpandableTableTest.nwb'];
            nwbExport(testCase.file, filename);
            readFile = nwbRead(filename);
            %add rows to expandable table and export
            for i = 101:200
                readFile.intervals_trials.addRow( ...
                    'start_time', start_time_array(i), ...
                    'stop_time', stop_time_array(i), ...
                    'randomvalues', random_val_array(i), ...
                    'id', id(i) ...
                )
            end
            nwbExport(readFile, filename)
            %read in expanded table
            readFile = nwbRead(filename);
            %test getRow
            actualData = readFile.intervals_trials.getRow(1:200, ...
                'columns', {'randomvalues'});
            testCase.verifyEqual(random_val_array, actualData.randomvalues);
        end
    end
end

