classdef DynamicTableTest < tests.system.RoundTripTest & tests.system.AmendTest
    methods
        function addContainer(~, file)
            colnames = {'start_time', 'stop_time', 'randomvalues', 'stringdata'};
            file.intervals_trials = types.core.TimeIntervals(...
                'description', 'test dynamic table column',...
                'colnames', colnames);
            
            id = primes(2000) .';
            for i = 1:100
                start_time = i;
                stop_time = i + 1;
                rand_data = rand(5,1);
                file.intervals_trials.addRow(...
                    'start_time', start_time,...
                    'stop_time', stop_time,...
                    'randomvalues', rand_data,...
                    'stringdata', {'TRUE'},...
                    'id', id(i),...
                    'tablepath', '/intervals/trials');
            end
            t = table(id(101:200), (101:200) .', (102:201) .', mat2cell(rand(500,1),...
                repmat(5, 100, 1)), repmat({'TRUE'}, 100, 1),...
                'VariableNames', {'id', 'start_time', 'stop_time', 'randomvalues', 'stringdata'});
            file.intervals_trials.addRow(t);
        end
        
        function c = getContainer(~, file)
            c = file.intervals_trials.vectordata.get('randomvalues');
        end
        
        function appendContainer(testCase, file)
            container = testCase.getContainer(file);
            container.data = rand(1000, 1); % new random values.
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

