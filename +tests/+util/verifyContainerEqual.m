function verifyContainerEqual(testCase, actual, expected)
testCase.verifyEqual(class(actual), class(expected));
props = properties(actual);
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
    elseif isdatetime(expectedVal)
        % ubuntu MATLAB doesn't appear to propery compare datetimes whereas
        % Windows MATLAB does. This is a workaround to get tests to work
        % while getting close enough to exact date representation.
        testCase.verifyEqual(char(actualVal), char(expectedVal), failmsg);
    else
        if strcmp(prop, 'file_create_date')
            % file_create_date is a very special property in NWBFile which can
            % be many array formats and either a datetime or not.
            % as such, we rely on the superpower of checkDtype to coerce
            % the type for us.
            actualVal = types.util.checkDtype('file_create_date', 'isodatetime', actualVal);
        end
        testCase.verifyEqual(actualVal, expectedVal, failmsg);
    end
end
end