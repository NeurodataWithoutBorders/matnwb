function verifyContainerEqual(testCase, actual, expected)
testCase.verifyEqual(class(actual), class(expected));
props = properties(actual);
for i = 1:numel(props)
    prop = props{i};
    val1 = actual.(prop);
    val2 = expected.(prop);
    failmsg = ['Values for property ''' prop ''' are not equal'];
    
    if isa(val1, 'types.untyped.DataStub')
        val1 = val1.load();
    end

    if startsWith(class(val2), 'types.') && ~startsWith(class(val2), 'types.untyped')
        tests.util.verifyContainerEqual(testCase, val1, val2);
    elseif isa(val2, 'types.untyped.Set')
        tests.util.verifySetEqual(testCase, val1, val2, failmsg);
    elseif isdatetime(val2)
        testCase.verifyEqual(char(val1), char(val2), failmsg);
    elseif ischar(val2)
        testCase.verifyEqual(char(val1), val2, failmsg);
    elseif isa(val2, 'types.untyped.ObjectView')
        testCase.verifyEqual(val1.path, val2.path, failmsg);
    elseif isa(val2, 'types.untyped.RegionView')
        testCase.verifyEqual(val1.path, val2.path, failmsg);
        testCase.verifyEqual(val1.region, val2.region, failmsg);
    elseif isa(val2, 'types.untyped.Anon')
        testCase.verifyEqual(val1.name, val2.name, failmsg);
        tests.util.verifyContainerEqual(testCase, val1.value, val2.value);
    else
        testCase.verifyEqual(val1, val2, failmsg);
    end
end
end