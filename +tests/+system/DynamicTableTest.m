classdef DynamicTableTest < tests.system.RoundTripTest & tests.system.AmendTest
    methods
        function addContainer(~, file)
            colnames = {'start_time', 'stop_time', 'randomvalues'};
            file.intervals_trials = types.core.TimeIntervals(...
                'description', 'test dynamic table column',...
                'colnames', colnames);
            
            for i = 1:100
                start_time = i;
                stop_time = i + 1;
                rand_data = rand(5,1);
                id = primes(i);
                if isempty(id)
                    id = 0;
                else
                    id = id(end);
                end
                file.intervals_trials.addRow(...
                    'start_time', start_time,...
                    'stop_time', stop_time,...
                    'randomvalues', rand_data,...
                    'id', id,...
                    'tablepath', '/intervals/trials');
            end
        end
        
        function c = getContainer(~, file)
            c = file.intervals_trials.vectordata.get('randomvalues');
        end
        
        function appendContainer(testCase, file)
            container = testCase.getContainer(file);
            container.data = rand(500, 1); % new random values.
            file.intervals_trials.colnames{end+1} = 'newcolumn';
            file.intervals_trials.vectordata.set('newcolumn',...
                types.hdmf_common.VectorData(...
                'description', 'newly added column',...
                'data', 100:-1:1));
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
            testCase.verifyEqual(ExpectedTable.getRow(97, 'useId', true),...
                ActualTable.getRow(97, 'useId', true));
        end
    end
end

