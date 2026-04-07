classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...        
    testCreateParsedType < matlab.unittest.TestCase

    methods (TestMethodSetup)
        function setupMethod(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
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
            testPath = 'some/dataset/path';
            testType = 'types.hdmf_common.VectorIndex';
            kwargs = {'data', 'text is not numeric indices'};

            try
                io.createParsedType(testPath, testType, kwargs{:});
                testCase.verifyFail('Expected io.createParsedType to throw an error.');
            catch exception
                testCase.verifyEqual(...
                    exception.identifier, ...
                    'NWB:createParsedType:TypeCreationFailed');
                testCase.verifyNotEmpty(strfind(exception.message, testType));
                testCase.verifyNotEmpty(strfind(exception.message, testPath));
            end
        end
    end
end
