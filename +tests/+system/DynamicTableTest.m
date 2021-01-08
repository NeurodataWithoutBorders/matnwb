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
                rand_data = rand(2,1);
                file.intervals_trials.addRow(...
                    'start_time', start_time,...
                    'stop_time', stop_time,...
                    'randomvalues', rand_data,...
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
end

