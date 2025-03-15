classdef ValidateLocationTest < matlab.unittest.TestCase
    methods (Test)
        function testAbsolutePath(testCase)
            % Test path that already starts with /
            input = "/path/to/group";
            result = io.internal.h5.validateLocation(input);
            testCase.verifyEqual(result, input, ...
                'Absolute path should remain unchanged');
        end
        
        function testRelativePath(testCase)
            % Test path without leading /
            input = "path/to/group";
            expected = "/path/to/group";
            result = io.internal.h5.validateLocation(input);
            testCase.verifyEqual(result, expected, ...
                'Relative path should be converted to absolute');
        end
    end
end
