function tests = smokeTest()
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
% corePath = fullfile(rootPath, 'schema', 'core', 'nwb.namespace.yaml');
% testCase.TestData.registry = generateCore(corePath);
end

function teardownOnce(testCase)
% classes = fieldnames(testCase.TestData.registry);
% files = strcat(fullfile('+types', classes), '.m');
% delete(files{:});
end

function setup(testCase)
testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
end

%TODO rewrite namespace instantiation check
function testSmokeInstantiateCore(testCase)
% classes = fieldnames(testCase.TestData.registry);
% for i = 1:numel(classes)
%     c = classes{i};
%     try
%         types.(c);
%     catch e
%         testCase.verifyFail(['Could not instantiate types.' c ' : ' e.message]);
%     end
% end
end

function testSmokeReadWrite(testCase)
file = nwbfile();
epochs = types.core.EpochTable;
md = types.core.DynamicTable('id', types.core.ElementIdentifiers('data', int64(1)));
ts = types.core.TimeSeriesIndex;
file.epochs = types.core.Epochs('epochs', epochs, 'metadata', md, 'timeseries_index', ts);
nwbExport(file, 'epoch.nwb');
readFile = nwbRead('epoch.nwb');
% testCase.verifyEqual(testCase, readFile, file, ...
%     'Could not write and then read a simple file');
verifyContainerEqual(testCase, readFile, file);

    function verifyContainerEqual(testCase, actual, expected)
        testCase.verifyEqual(class(actual), class(expected));
        props = properties(actual);
        for i = 1:numel(props)
            prop = props{i};
            val1 = actual.(prop);
            val2 = expected.(prop);
            if startsWith(class(val1), 'types.core.')
                verifyContainerEqual(testCase, val1, val2);
            elseif isa(val1, 'types.untyped.Set')
                verifySetEqual(testCase, val1, val2);
            else
                switch class(val1)
                    case 'types.untyped.DataStub'
                        trueval = val1.load();
                    otherwise
                        trueval = val1;
                end
                testCase.verifyEqual(trueval, val2);
            end
        end
    end
    function verifySetEqual(testCase, actual, expected)
        testCase.verifyEqual(class(actual), class(expected));
        ak = actual.keys();
        ek = expected.keys();
        verifyTrue(testCase, isempty(setxor(ak, ek)));
        for i=1:numel(ak)
            key = ak{i};
            verifyContainerEqual(testCase, actual.get(key), ...
                expected.get(key));
        end
    end
end