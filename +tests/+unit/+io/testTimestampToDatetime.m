classdef testTimestampToDatetime < matlab.unittest.TestCase
% Specific tests for function io.timestamp2datetime

    properties
        TimestampList = ["2023-05-05", "2024-06-06"]
        Expected = datetime(["2023-05-05", "2024-06-06"], "InputFormat", "uuuu-MM-dd")
    end

    properties
        NWBDefaultStringFormat = "uuuu-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ";
    end

    methods (Test)
        function testNonDatestamp(testCase)
            testCase.verifyError(@() io.timestamp2datetime("Hello World"), ...
                "NWB:InvalidTimestamp")
        end

        function testNonStringInput(testCase)
            timestamp = [2022, 3, 4];
            testCase.verifyError(@() io.timestamp2datetime(timestamp), ...
                "NWB:timestamp2datetime:MustBeCharCellArrayOrString" )
        end

        function testCharInput(testCase)
            timestamps = char(testCase.TimestampList(1)); % Convert to char
            actual = io.timestamp2datetime(timestamps);
            testCase.verifyEqual(actual, testCase.Expected(1));
        end

        function testStringInput(testCase)
            actual = io.timestamp2datetime(testCase.TimestampList);
            testCase.verifyEqual(actual, testCase.Expected);
        end

        function testCellArrayInput(testCase)
            timestamps = cellstr(testCase.TimestampList); % Convert to cell

            actual = io.timestamp2datetime(timestamps);
            testCase.verifyEqual(actual, testCase.Expected);
        end

        function testValidTimestampWithTimezone(testCase)
            timestamp = "2023-07-23T15:30:00Z";
            expected = datetime(timestamp, "InputFormat", "uuuu-MM-dd'T'HH:mm:ssZ", 'TimeZone', 'UTC');
            actual = io.timestamp2datetime(timestamp);
            testCase.verifyEqual(actual, expected);
        end

        function testTimestampWithInvalidTimeZone(testCase)
            timestamps = "20230723T15000000ZAmerica/Oslo";
            testCase.verifyError(@() io.timestamp2datetime(timestamps), 'MATLAB:datetime:UnknownTimeZone');
        end

        function testPartialTimestampWithDash(testCase)
            partialTimestamp = "2023-07";
            testCase.verifyError(@() io.timestamp2datetime(partialTimestamp), 'NWB:InvalidTimestamp');
        end

        function testPartialTimestampWithoutDash(testCase)
            timestamps = "20230723";
            actual = io.timestamp2datetime(timestamps);
            expected = datetime("2023-07-23", "InputFormat", "uuuu-MM-dd");
            testCase.verifyEqual(actual, expected);
        end

        function testTimestampWithTimeNoTimeZone(testCase)
            timestamp = "20230723T15:00:00";
            expected = datetime("2023-07-23T15:00:00", "InputFormat", "uuuu-MM-dd'T'HH:mm:ss");
            actual = io.timestamp2datetime(timestamp);
            testCase.verifyEqual(actual, expected);
        end
        
        function testTimestampWithMilliseconds(testCase)
            timestamp = "20230723T150000000";
            expected = datetime("2023-07-23T15:00:00", "InputFormat", "uuuu-MM-dd'T'HH:mm:ss");
            actual = io.timestamp2datetime(timestamp);
            testCase.verifyEqual(actual, expected);
        end
    
        function testCurrentYear(testCase)
            currentYear = year(datetime("now", 'TimeZone', 'local')); % Specify the year
            startDate = datetime(currentYear, 1, 1, 'TimeZone', 'local'); % Start date: January 1st
            endDate = datetime(currentYear, 12, 31, 'TimeZone', 'local'); % End date: December 31st
            
            % Generate all dates for the year
            allDates = startDate:calmonths(1):endDate;

            % Alternative: Only test last day of each month:
            % allDates = (startDate:calmonths(1):endDate) + calmonths(1) - caldays(1);
            allDates.Format = testCase.NWBDefaultStringFormat;

            numFailed = 0;

            for i = 1:numel(allDates)
                actual = io.timestamp2datetime( string(allDates(i)) );
                expected = allDates(i);

                if ~isequal(actual, expected)
                    numFailed = numFailed + 1;
                end
            end

            testCase.verifyEqual(numFailed, 0)
        end
    end
end
