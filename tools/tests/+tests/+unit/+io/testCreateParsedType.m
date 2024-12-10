function tests = testCreateParsedType()
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..', '..');
    testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));

    testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
    generateCore('savedir', '.')
end

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
    type = io.createParsedType(testPath, testType, kwargs{:});
    testCase.verifyClass(type, testType)

    testCase.verifyWarning(...
        @(varargin)io.createParsedType(testPath, testType, kwargs{:}), ...
        'NWB:CheckUnset:InvalidProperties')
end