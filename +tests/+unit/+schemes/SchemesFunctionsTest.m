classdef SchemesFunctionsTest < tests.abstract.NwbTestCase
% SchemesFunctionsTest - Unit tests for functions in the schemes namespace
    methods (Test)
        function testFindRootDirectoryForGeneratedTypes(testCase)
            generatedTypesFolder = schemes.utility.findRootDirectoryForGeneratedTypes();
            testCase.verifyTrue(isfolder(generatedTypesFolder))
        end

        function testFindRootDirectoryForGeneratedTypesIfMissing(testCase)
            import tests.fixtures.NwbClearGeneratedFixture
            testCase.applyFixture(NwbClearGeneratedFixture(testCase.getTypesOutputFolder))
            testCase.verifyError(...
                @() schemes.utility.findRootDirectoryForGeneratedTypes(), ...
                'NWB:Types:GeneratedTypesNotFound')
        end

        function testFindRootDirectoryForGeneratedTypesWithDuplicates(testCase)
            % Generate types in temp working folder. Will produce an extra
            % set of generated types on MATLAB's search path
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            generateCore('savedir', '.') 
            testCase.verifyWarning(...
                @() schemes.utility.findRootDirectoryForGeneratedTypes(), ...
                'NWB:Types:MultipleGeneratedTypesFound')
        end
    end
end
