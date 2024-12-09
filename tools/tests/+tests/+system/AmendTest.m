classdef AmendTest < tests.system.NwbTestInterface
    methods (Test)
        function testAmend(testCase)
            filename = ['MatNWB.' testCase.className() '.testAmend.nwb'];
            nwbExport(testCase.file, filename);
            testCase.appendContainer(testCase.file);
            nwbExport(testCase.file, filename);
            
            writeContainer = testCase.getContainer(testCase.file);
            readFile = nwbRead(filename, 'ignorecache');
            readContainer = testCase.getContainer(readFile);
            tests.util.verifyContainerEqual(testCase, readContainer, writeContainer);
        end
    end
    
    methods (Abstract)
        appendContainer(testCase, file);
    end
end

