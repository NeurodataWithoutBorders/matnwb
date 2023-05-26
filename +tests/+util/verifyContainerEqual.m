function verifyContainerEqual(testCase, actual, expected, ignoreList)
if nargin < 4
    ignoreList = {};
end
assert(iscellstr(ignoreList),...
    'NWB:Test:InvalidIgnoreList',...
    ['Ignore List must be a cell array of character arrays indicating props that should be '...
    'ignored.']);
testCase.verifyEqual(class(actual), class(expected));
props = setdiff(properties(actual), ignoreList);
for i = 1:numel(props)
    prop = props{i};
    
    actualVal = actual.(prop);
    expectedVal = expected.(prop);
    failmsg = ['Values for property ''' prop ''' are not equal'];
    
    if isa(actualVal, 'types.untyped.DataStub')
        actualVal = actualVal.load();
    end
    
    if startsWith(class(expectedVal), 'types.') && ~startsWith(class(expectedVal), 'types.untyped')
        tests.util.verifyContainerEqual(testCase, actualVal, expectedVal);
    elseif isa(expectedVal, 'types.untyped.Set')
        tests.util.verifySetEqual(testCase, actualVal, expectedVal, failmsg);
    elseif ischar(expectedVal)
        testCase.verifyEqual(char(actualVal), expectedVal, failmsg);
    elseif isa(expectedVal, 'types.untyped.ObjectView') || isa(expectedVal, 'types.untyped.SoftLink')
        testCase.verifyEqual(actualVal.path, expectedVal.path, failmsg);
    elseif isa(expectedVal, 'types.untyped.RegionView')
        testCase.verifyEqual(actualVal.path, expectedVal.path, failmsg);
        testCase.verifyEqual(actualVal.region, expectedVal.region, failmsg);
    elseif isa(expectedVal, 'types.untyped.Anon')
        testCase.verifyEqual(actualVal.name, expectedVal.name, failmsg);
        tests.util.verifyContainerEqual(testCase, actualVal.value, expectedVal.value);
    elseif isdatetime(expectedVal)...
            || (iscell(expectedVal) && all(cellfun('isclass', expectedVal, 'datetime')))
        % linux MATLAB doesn't appear to propery compare datetimes whereas
        % Windows MATLAB does. This is a workaround to get tests to work
        % while getting close enough to exact date representation.
        actualVal = types.util.checkDtype(prop, 'datetime', actualVal);
        if ~iscell(expectedVal)
            expectedVal = {expectedVal};
        end
        if ~iscell(actualVal)
            actualVal = {actualVal};
        end
        for iDates = 1:length(expectedVal)
            % ignore microseconds as linux datetime has some strange error
            % even when datetime doesn't change in Windows.
            actualNtfs = convertTo(actualVal{iDates}, 'ntfs');
            expectedNtfs = convertTo(expectedVal{iDates}, 'ntfs');
            testCase.verifyGreaterThanOrEqual(actualNtfs, expectedNtfs - 10, failmsg);
            testCase.verifyLessThanOrEqual(actualNtfs, expectedNtfs + 10, failmsg);
        end
    elseif startsWith(class(expectedVal), 'int')
        testCase.verifyEqual(int64(actualVal), int64(expectedVal), failmsg);
    elseif startsWith(class(expectedVal), 'uint')
        testCase.verifyEqual(uint64(actualVal), uint64(expectedVal), failmsg);
    else
        testCase.verifyEqual(actualVal, expectedVal, failmsg);
    end
end
end