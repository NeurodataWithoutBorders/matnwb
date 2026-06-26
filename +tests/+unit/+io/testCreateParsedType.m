classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...        
    testCreateParsedType < matlab.unittest.TestCase

    methods (TestMethodSetup)
        function setupMethod(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            previousReportingSource = matnwb.common.validation.internal.reportingSource([]);
            testCase.addTeardown( ...
                @() matnwb.common.validation.internal.reportingSource(previousReportingSource));
        end
    end

    methods (Test)
        function testCreateTypeWithValidInputs(testCase)
            testPath = 'some/dataset/path';
            testType = 'types.hdmf_common.VectorIndex';
            kwargs = {'description', 'this is a test'};
        
            type = io.createParsedType(testPath, testType, kwargs{:});
            testCase.verifyClass(type, testType)
        
            testCase.verifyWarningFree(...
                @(varargin)io.createParsedType(testPath, testType, kwargs{:}))
        end
        
        function testCreateTypeWithInvalidInputs(testCase)        
            testPath = 'some/dataset/path';
            testType = 'types.hdmf_common.VectorIndex';
            kwargs = {'description', 'this is a test', 'comment', 'this is another test'};
            
            type = testCase.verifyWarning(...
                @(varargin) io.createParsedType(testPath, testType, kwargs{:}), ...
                'NWB:CheckUnset:InvalidProperties');

            testCase.verifyClass(type, testType)
        end

        function testCreateTypeWithInvalidPropertyValue(testCase)
            % An invalid property value is read permissively: createParsedType
            % warns and keeps the value instead of failing the read (#776).
            testPath = 'some/dataset/path';
            testType = 'types.hdmf_common.VectorIndex';
            kwargs = {'data', 'text is not numeric indices'};

            type = testCase.verifyWarning(...
                @() io.createParsedType(testPath, testType, kwargs{:}), ...
                'NWB:CheckDataType:InvalidConversion');

            testCase.verifyClass(type, testType)
            [warningMessage, warningId] = lastwarn();
            testCase.verifyEqual(warningId, 'NWB:CheckDataType:InvalidConversion')
            testCase.verifySubstring(warningMessage, testPath)
            testCase.verifySubstring(warningMessage, testType)
        end

        function testCreateDynamicTableWithDuplicateColnamesWarns(testCase)
            testPath = 'some/dynamic_table/path';
            testType = 'types.hdmf_common.DynamicTable';
            kwargs = { ...
                'description', 'legacy dynamic table', ...
                'colnames', {'columnA', 'columnA'}, ...
                'columnA', types.hdmf_common.VectorData( ...
                    'description', 'column a', ...
                    'data', (1:3)')};

            dynamicTable = testCase.verifyWarning( ...
                @() io.createParsedType(testPath, testType, kwargs{:}), ...
                'NWB:DynamicTable:DuplicateColumnNames');

            testCase.verifyClass(dynamicTable, testType)
            [warningMessage, warningIdentifier] = lastwarn();
            testCase.verifyEqual( ...
                warningIdentifier, 'NWB:DynamicTable:DuplicateColumnNames')
            testCase.verifyTrue(contains(warningMessage, '`columnA`'))
        end

        function testCreateDynamicTableWithColumnNamesMismatchWarns(testCase)
            testPath = 'some/time_intervals/path';
            testType = 'types.core.TimeIntervals';
            kwargs = { ...
                'description', 'legacy time intervals table', ...
                'colnames', {'stop_time'}, ...
                'start_time', types.hdmf_common.VectorData( ...
                    'description', 'start time column', ...
                    'data', single((1:3)')), ...
                'stop_time', types.hdmf_common.VectorData( ...
                    'description', 'stop time column', ...
                    'data', single((2:4)'))};

            dynamicTable = testCase.verifyWarning( ...
                @() io.createParsedType(testPath, testType, kwargs{:}), ...
                'NWB:DynamicTable:CheckConfig:ColumnNamesMismatch');

            testCase.verifyClass(dynamicTable, testType)
            testCase.verifyEqual(dynamicTable.colnames, {'stop_time'})
        end

        function testCheckConfigDoesNotRevalidateDuplicateColnamesOnRead(testCase)
            previousValidationContext = matnwb.common.validation.internal.context("read");
            cleanupContext = onCleanup( ...
                @() matnwb.common.validation.internal.context(previousValidationContext));

            warningState = warning('off', 'NWB:DynamicTable:DuplicateColumnNames');
            cleanupWarning = onCleanup(@() warning(warningState));

            dynamicTable = types.hdmf_common.DynamicTable( ...
                'description', 'legacy dynamic table', ...
                'colnames', {'columnA', 'columnA'});

            warning('error', 'NWB:DynamicTable:DuplicateColumnNames')

            testCase.verifyWarningFree( ...
                @() types.util.dynamictable.checkConfig(dynamicTable));

            clear cleanupContext cleanupWarning
        end

        function testCreateParsedTypeRestoresStrictValidationContext(testCase)
            testPath = 'some/dynamic_table/path';
            testType = 'types.hdmf_common.DynamicTable';
            kwargs = { ...
                'description', 'legacy dynamic table', ...
                'colnames', {'columnA', 'columnA'}};

            testCase.verifyWarning( ...
                @() io.createParsedType(testPath, testType, kwargs{:}), ...
                'NWB:DynamicTable:DuplicateColumnNames');

            testCase.verifyError( ...
                @() types.hdmf_common.DynamicTable( ...
                    'description', 'new dynamic table', ...
                    'colnames', {'columnA', 'columnA'}), ...
                'NWB:DynamicTable:DuplicateColumnNames');
            testCase.verifyEmpty( ...
                matnwb.common.validation.internal.reportingSource())
        end
    end
end
