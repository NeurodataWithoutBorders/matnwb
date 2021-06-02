classdef NwbTestInterface < matlab.unittest.TestCase
    properties
        %     registry
        file
        root;
    end
    
    methods (TestClassSetup)
        function setupClass(testCase)
            rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
            testCase.root = rootPath;
        end
    end
    
    methods (TestMethodSetup)
        function setupMethod(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            generateCore();
            testCase.file = NwbFile( ...
                'session_description', 'a test NWB File', ...
                'identifier', 'TEST123', ...
                'session_start_time', '2018-12-02T12:57:27.371444-08:00', ...
                'file_create_date', '2017-04-15T12:00:00.000000-08:00',...
                'timestamps_reference_time', '2018-12-02T12:57:27.371444-08:00');
            testCase.addContainer(testCase.file);
        end
    end
    
    methods
        function n = className(testCase)
            classSplit = strsplit(class(testCase), '.');
            n = classSplit{end};
        end
        
        function verifyContainerEqual(testCase, actual, expected)
            testCase.verifyEqual(class(actual), class(expected));
            props = properties(actual);
            for i = 1:numel(props)
                prop = props{i};
                if strcmp(prop, 'file_create_date')
                    continue;
                end
                actualVal = actual.(prop);
                expectedVal = expected.(prop);
                failmsg = ['Values for property ''' prop ''' are not equal'];
                if startsWith(class(actualVal), 'types.')...
                        && ~startsWith(class(actualVal), 'types.untyped')
                    verifyContainerEqual(testCase, actualVal, expectedVal);
                elseif isa(actualVal, 'types.untyped.Set')
                    verifySetEqual(testCase, actualVal, expectedVal, failmsg);
                elseif isdatetime(actualVal)
                    testCase.verifyEqual(char(actualVal), char(expectedVal), failmsg);
                else
                    if isa(actualVal, 'types.untyped.DataStub')
                        actualTrue = actualVal.load();
                    else
                        actualTrue = actualVal;
                    end
                    
                    if isvector(expectedVal) && isvector(actualTrue) && numel(expectedVal) == numel(actualTrue)
                        actualTrue = reshape(actualTrue, size(expectedVal));
                    end
                    
                    if isinteger(actualTrue) && isinteger(expectedVal)
                        actualSize = class(actualTrue);
                        actualSize = str2double(actualSize(4:end));
                        expectedSize = class(expectedVal);
                        expectedSize = str2double(expectedSize(4:end));
                        testCase.verifyGreaterThanOrEqual(actualSize, expectedSize, failmsg);
                        testCase.verifyEqual(double(actualTrue), double(expectedVal), failmsg);
                        continue;
                    end
                    testCase.verifyEqual(actualTrue, expectedVal, failmsg);
                end
            end
        end
        
        function verifySetEqual(testCase, actual, expected, failmsg)
            testCase.verifyEqual(class(actual), class(expected));
            ak = actual.keys();
            ek = expected.keys();
            verifyTrue(testCase, isempty(setxor(ak, ek)), failmsg);
            for i=1:numel(ak)
                key = ak{i};
                verifyContainerEqual(testCase, actual.get(key), ...
                    expected.get(key));
            end
        end
        
        function verifyUntypedEqual(testCase, actual, expected)
            testCase.verifyEqual(class(actual), class(expected));
            props = properties(actual);
            for i = 1:numel(props)
                prop = props{i};
                val1 = actual.(prop);
                val2 = expected.(prop);
                if isa(val1, 'types.core.NWBContainer') || isa(val1, 'types.core.NWBData')
                    verifyContainerEqual(testCase, val1, val2);
                else
                    testCase.verifyEqual(val1, val2, ...
                        ['Values for property ''' prop ''' are not equal']);
                end
            end
        end
        
    end
    
    methods(Abstract)
        addContainer(testCase, file);
        c = getContainer(testCase, file);
    end
end

