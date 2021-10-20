classdef ExpandableTableTest < tests.system.NwbTestInterface
    methods
        function addContainer(~, file)
            
            %create data arrays
            nrows = 100;
            id = primes(2000) .';
            id = id(1:nrows);
            start_time_array = 1:nrows;
            stop_time_array = start_time_array+1;
            rng(1);%to be able replicate random values
            random_val_array = rand(nrows,1);
            
            %create VectorData objects with DataPipe objects
            start_time_exp = types.hdmf_common.VectorData( ...
                'description','start times',...
                'data', types.untyped.DataPipe('data', start_time_array', ...
                    'maxSize', [Inf, 1], ...
                    'axis', 1 ...
                ) ...
            );
            stop_time_exp = types.hdmf_common.VectorData(...
                'description','stop times',...
                'data',types.untyped.DataPipe('data',  stop_time_array', ...
                    'maxSize', [Inf, 1], ...
                    'axis', 1 ...
                ) ...
            );
            random_exp = types.hdmf_common.VectorData(...
                'description','random data column',...
                'data',types.untyped.DataPipe('data', random_val_array, ...
                    'maxSize', [Inf, 1], ...
                    'axis', 1 ...
                ) ...
            );
            ids_exp = types.hdmf_common.ElementIdentifiers('data', ...
                types.untyped.DataPipe('data', id, ... 
                    'maxSize', [Inf, 1], ...
                    'axis', 1 ...
                    )...
                );
            %create expandable table
            colnames = {'start_time', 'stop_time', 'randomvalues'};
            file.intervals_trials = types.core.TimeIntervals(...
                'description', 'test expdandable dynamic table',...
                'colnames', colnames,...
                'start_time',start_time_exp,...
                'stop_time',stop_time_exp,...
                'randomvalues',random_exp,...
                'id', ids_exp...
                );
        end
  
        function c = getContainer(~, file)
            c = file.intervals_trials.vectordata.get('randomvalues');
        end
        function file = getDummyFile(~,start_array,stop_array,random_array,id_array)
 

            %create VectorData objects with DataPipe objects
            start_time_exp = types.hdmf_common.VectorData(...
                'description','start times',...
                'data', start_array' ...
                );
            stop_time_exp = types.hdmf_common.VectorData(...
                'description','stop times',...
                'data', stop_array' ...
            );
            random_exp = types.hdmf_common.VectorData(...
                'description','random data column',...
                'data', random_array ...
            );
            ids_exp = types.hdmf_common.ElementIdentifiers('data', id_array...
                );
            
            %create dummy file
            file = NwbFile( ...
                'session_description', 'a test NWB File', ...
                'identifier', 'TEST456', ...
                'session_start_time', '2018-12-02T12:57:27.371444-08:00', ...
                'file_create_date', '2017-04-15T12:00:00.000000-08:00',...
                'timestamps_reference_time', '2018-12-02T12:57:27.371444-08:00');
            %create expandable table
            colnames = {'start_time', 'stop_time', 'randomvalues'};
            file.intervals_trials = types.core.TimeIntervals(...
                'description', 'test expdandable dynamic table',...
                'colnames', colnames,...
                'start_time',start_time_exp,...
                'stop_time',stop_time_exp,...
                'randomvalues',random_exp,...
                'id', ids_exp...
                );
        end
        
    end
    methods (Test)
        function RoundTripTest(testCase)
            filename = ['MatNWB.' testCase.className() '.testRoundTrip.nwb'];
            nwbExport(testCase.file, filename);
            writeContainer = testCase.getContainer(testCase.file);
            readFile = nwbRead(filename);
            readContainer = testCase.getContainer(readFile);
            tests.util.verifyContainerEqual(testCase, readContainer, writeContainer);
        end

        function getRowsExpandableTest(testCase)
            %create arrays for non-expandable table
            nrows = 200;
            id = primes(2000) .';
            id = id(1:nrows);
            start_time_array = 1:nrows;
            stop_time_array = start_time_array+1;
            rng(1);%to be able replicate random values
            random_val_array = rand(nrows,1);
            dummyFile = testCase.getDummyFile(start_time_array,stop_time_array,random_val_array,id);

            %export and read-in expandable table
            filename = ['MatNWB.' testCase.className() '.getRowsExpandableTest.nwb'];
            nwbExport(testCase.file, filename);
            readFile = nwbRead(filename);
            %add rows to expandable table and export
            for i = 101:200
                readFile.intervals_trials.addRow(...
                    'start_time',start_time_array(i),...
                    'stop_time',stop_time_array(i),...
                    'randomvalues',random_val_array(i),...
                    'id',id(i)...
                    )   
            end
            nwbExport(readFile, filename)
            %read in expanded table
            readFile = nwbRead(filename);
            %test getRow for original portion of table
            expectedData = dummyFile.intervals_trials.getRow(55,...
                'columns', {'randomvalues'});
            actualData = readFile.intervals_trials.getRow(55,...
                'columns', {'randomvalues'});
            %compare
            testCase.verifyEqual(expectedData, actualData);
            
            %test getRow for appended portion of table
            expectedData = dummyFile.intervals_trials.getRow(155,...
                'columns', {'randomvalues'});
            actualData = readFile.intervals_trials.getRow(155,...
                'columns', {'randomvalues'});
            %compare
            testCase.verifyEqual(expectedData, actualData);
   
        end
    end
end