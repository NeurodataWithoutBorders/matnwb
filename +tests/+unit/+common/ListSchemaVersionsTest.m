classdef ListSchemaVersionsTest < matlab.unittest.TestCase
% ListSchemaVersionsTest - Unit tests for matnwb.common.listSchemaVersions

    methods (Test)
        function testListsOnlyValidSchemaVersions(testCase)
            versionNumbers = matnwb.common.listSchemaVersions();

            testCase.verifyNotEmpty(versionNumbers)
            for versionNumber = versionNumbers
                matnwb.common.mustBeValidSchemaVersion(versionNumber)
            end
        end

        function testVersionsAreSortedNumerically(testCase)
            versionNumbers = matnwb.common.listSchemaVersions();

            versionComponents = double(split(versionNumbers(:), ".", 2));
            testCase.verifyTrue(issortedrows(versionComponents))
            testCase.verifyEqual(versionNumbers(end), ...
                string(matnwb.common.findLatestSchemaVersion()))
        end

        function testSignatureFileIsValid(testCase)
            signatureFile = fullfile(misc.getMatnwbDir(), ...
                'resources', 'functionSignatures.json');

            problems = validateFunctionSignaturesJSON(signatureFile);
            testCase.verifyEmpty(problems)
        end
    end
end
