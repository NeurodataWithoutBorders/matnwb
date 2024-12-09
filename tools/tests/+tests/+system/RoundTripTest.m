classdef RoundTripTest < tests.system.NwbTestInterface
    methods (Test)
        function testRoundTrip(testCase)
            filename = ['MatNWB.' testCase.className() '.testRoundTrip.nwb'];
            nwbExport(testCase.file, filename);
            writeContainer = testCase.getContainer(testCase.file);
            readFile = nwbRead(filename, 'ignorecache');
            readContainer = testCase.getContainer(readFile);
            tests.util.verifyContainerEqual(testCase, readContainer, writeContainer);
        end
    end
end