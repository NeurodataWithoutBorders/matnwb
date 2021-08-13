classdef GenerationTest < matlab.unittest.TestCase
    properties (MethodSetupParameter)
        schemaVersion = setdiff({dir('nwb-schema').name}, {'.', '..'});
    end
    
    methods (TestClassSetup)
        function setupClass(testCase)
            rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
        end
    end
    
    methods (TestMethodSetup)
        function setupMethod(testCase, schemaVersion)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            generateCore(schemaVersion);
            rehash();
        end
    end
    
    methods (Test)
        function roundtripTest(testCase)
            expected = NwbFile('identifier', 'TEST',...
                'session_description', 'test nwbfile',...
                'session_start_time', datetime());
            expected.export('empty.nwb');
            
            actual = nwbRead('empty.nwb');
            tests.util.verifyContainerEqual(testCase, actual, expected);
        end
        
        function dynamicTableMethodsTest(testCase)
            % assure that dynamic table methods consider legacy modes as
            % well.
            colnames = {'start_time', 'stop_time', 'randomvalues', 'stringdata'};
            TimeIntervals = types.core.TimeIntervals(...
                'description', 'test dynamic table column',...
                'colnames', colnames);
            
            id = primes(2000) .';
            for i = 1:100
                start_time = i;
                stop_time = i + 1;
                rand_data = rand(5,1);
                TimeIntervals.addRow(...
                    'start_time', start_time,...
                    'stop_time', stop_time,...
                    'randomvalues', rand_data,...
                    'stringdata', {'TRUE'},...
                    'id', id(i));
            end
            t = table(id(101:200), (101:200) .', (102:201) .',...
                mat2cell(rand(500,1), repmat(5, 100, 1)), repmat({'TRUE'}, 100, 1),...
                'VariableNames', {'id', 'start_time', 'stop_time', 'randomvalues', 'stringdata'});
            TimeIntervals.addRow(t);
            
            retrievalIndex = round(1 + 199 .* rand(10, 1));
            indexedRow = TimeIntervals.getRow(retrievalIndex);
            idRow = TimeIntervals.getRow(id(retrievalIndex), 'useId', true);
            testCase.verifyEqual(indexedRow, idRow);
        end
    end
end

