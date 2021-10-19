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
    end
end

