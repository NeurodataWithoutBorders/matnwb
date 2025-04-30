classdef GenerationTest < matlab.unittest.TestCase
% Note: Sometimes this test does not work for the first two schema versions. 
% Restarting MATLAB can fix this.

    properties (MethodSetupParameter)
        schemaVersion = listSchemaVersions()
    end
    
    methods (TestClassSetup)
        function setupMatNWBPathFixture(testCase)
            import matlab.unittest.fixtures.PathFixture
            matNwbRootPath = tests.util.getProjectDirectory();
            testCase.applyFixture( PathFixture(matNwbRootPath) );
        end

        function setupNwbClearGeneratedFixture(testCase)
            import tests.fixtures.NwbClearGeneratedFixture
            testCase.applyFixture( NwbClearGeneratedFixture );
        end
    end
    
    methods (TestMethodSetup)
        function setupMethod(testCase, schemaVersion)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            generateCore(schemaVersion, 'savedir', '.');
            rehash();
        end
    end
    
    methods (Test)
        function roundtripTest(testCase)
            expected = NwbFile('identifier', 'TEST',...
                'session_description', 'test nwbfile',...
                'session_start_time', datetime());
            nwbExport(expected, 'empty.nwb');
            tests.util.verifyContainerEqual(testCase, ...
                nwbRead('empty.nwb', 'ignorecache'), ...
                expected);
        end
        
        function dynamicTableMethodsTest(testCase)
            % assure that dynamic table methods consider legacy modes as
            % well.
            colnames = {'start_time', 'stop_time', 'randomvalues', 'stringdata'};
            TimeIntervals = types.core.TimeIntervals(...
                'description', 'test dynamic table column',...
                'colnames', colnames);
            
            id = primes(200) .';
            for i = 1:5
                TimeIntervals.addRow(...
                    'start_time', i,...
                    'stop_time', i + 1,...
                    'randomvalues', rand(5,1),...
                    'stringdata', {'TRUE'},...
                    'id', id(i));
            end
           t = table(id(6:10), (6:10)', (7:11)', ...
                rand(5,1), repmat({'TRUE'}, 5, 1), ...
                'VariableNames', {'id', 'start_time', 'stop_time', 'randomvalues', 'stringdata'});
            % verify error is thrown when addRow input is MATLAB table
            testCase.verifyError(@() TimeIntervals.addRow(t), ...
                "NWB:DynamicTable" ...
            );
            
            retrievalIndex = round(1 + 4 .* rand(10, 1));
            indexedRow = TimeIntervals.getRow(retrievalIndex);
            idRow = TimeIntervals.getRow(id(retrievalIndex), 'useId', true);
            testCase.verifyEqual(indexedRow, idRow);
        end
    end
end

function schemaVersions = listSchemaVersions()
    nwbSchemaDir = fullfile(misc.getMatnwbDir, 'nwb-schema');
    schemaVersions = setdiff({dir(nwbSchemaDir).name}, {'.', '..'});
end
