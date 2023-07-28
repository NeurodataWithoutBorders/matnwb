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
    for iProperty = 1:numel(props)
        prop = props{iProperty};

        actualValue = actual.(prop);
        expectedValue = expected.(prop);
        failureMessage = ['Values for property ''' prop ''' are not equal'];

        if isa(actualValue, 'types.untyped.DataStub')
            actualValue = actualValue.load();
        end

        if startsWith(class(expectedValue), 'types.') && ~startsWith(class(expectedValue), 'types.untyped')
            tests.util.verifyContainerEqual(testCase, actualValue, expectedValue);
        elseif isa(expectedValue, 'types.untyped.Set')
            tests.util.verifySetEqual(testCase, actualValue, expectedValue, failureMessage);
        elseif ischar(expectedValue)
            testCase.verifyEqual(char(actualValue), expectedValue, failureMessage);
        elseif isa(expectedValue, 'types.untyped.ObjectView') || isa(expectedValue, 'types.untyped.SoftLink')
            testCase.verifyEqual(actualValue.path, expectedValue.path, failureMessage);
        elseif isa(expectedValue, 'types.untyped.RegionView')
            testCase.verifyEqual(actualValue.path, expectedValue.path, failureMessage);
            testCase.verifyEqual(actualValue.region, expectedValue.region, failureMessage);
        elseif isa(expectedValue, 'types.untyped.Anon')
            testCase.verifyEqual(actualValue.name, expectedValue.name, failureMessage);
            tests.util.verifyContainerEqual(testCase, actualValue.value, expectedValue.value);
        elseif isdatetime(expectedValue)...
                || (iscell(expectedValue) && all(cellfun('isclass', expectedValue, 'datetime')))
            % linux MATLAB doesn't appear to propery compare datetimes whereas
            % Windows MATLAB does. This is a workaround to get tests to work
            % while getting close enough to exact date representation.
            actualValue = types.util.checkDtype(prop, 'datetime', actualValue);
            if ~iscell(expectedValue)
                expectedValue = num2cell(expectedValue);
            end
            if ~iscell(actualValue)
                actualValue = num2cell(actualValue);
            end
            for iDates = 1:length(expectedValue)
                % ignore microseconds as linux datetime has some strange error
                % even when datetime doesn't change in Windows.
                ActualDate = actualValue{iDates};
                ExpectedDate = expectedValue{iDates};
                ExpectedUpperBound = ExpectedDate + milliseconds(1);
                ExpectedLowerBound = ExpectedDate - milliseconds(1);
                testCase.verifyTrue(isbetween(ActualDate, ExpectedLowerBound, ExpectedUpperBound) ...
                    , failureMessage);
            end
        elseif startsWith(class(expectedValue), 'int')
            testCase.verifyEqual(int64(actualValue), int64(expectedValue), failureMessage);
        elseif startsWith(class(expectedValue), 'uint')
            testCase.verifyEqual(uint64(actualValue), uint64(expectedValue), failureMessage);
        elseif isstruct(expectedValue) || istable(expectedValue)
            if istable(expectedValue)
                fieldNames = expectedValue.Properties.VariableNames;
            else
                fieldNames = fieldnames(expectedValue);
            end
            fieldNames = convertStringsToChars(fieldNames);
            testCase.verifyTrue(isstruct(actualValue) || istable(actualValue), failureMessage);
            for iField = 1:length(fieldNames)
                name = fieldNames{iField};
                testCase.verifyEqual(actualValue.(name), expectedValue.(name), failureMessage);
            end
        else
            testCase.verifyEqual(actualValue, expectedValue, failureMessage);
        end
    end
end