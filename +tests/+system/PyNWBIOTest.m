classdef (SharedTestFixtures = {tests.fixtures.SetEnvironmentVariableFixture}) ...
        PyNWBIOTest < tests.system.RoundTripTest
    % Assumes PyNWB and unittest2 has been installed on the system.
    %
    % To install PyNWB, execute:
    % $ pip install pynwb
    %
    % To install unittest2, execute:
    % $ pip install unittest2
    methods(Test)
        function testOutToPyNWB(testCase)
            filename = ['MatNWB.' testCase.className() '.testOutToPyNWB.nwb'];
            nwbExport(testCase.file, filename);
            [status, cmdout] = testCase.runPyTest('testInFromMatNWB');
            if status
                testCase.verifyFail(cmdout);
            end
        end
        
        function testInFromPyNWB(testCase)
            [status, cmdout] = testCase.runPyTest('testOutToMatNWB');
            if status
                testCase.assertFail(cmdout);
            end
            filename = ['PyNWB.' testCase.className() '.testOutToMatNWB.nwb'];
            pyfile = nwbRead(filename, 'savedir', '.');
            pycontainer = testCase.getContainer(pyfile);
            matcontainer = testCase.getContainer(testCase.file);
            nwbExport(testCase.file, 'temp.nwb'); % hack to fill out ObjectView container paths.
            % ignore file_create_date because nwbExport will actually
            % mutate the property every export.
            % ignore general/was_generated_by because the value will be
            % specific to matnwb generated file.
            ignoreFields = {'file_create_date', 'general_was_generated_by'};
            tests.util.verifyContainerEqual(testCase, pycontainer, matcontainer, ignoreFields);
        end
    end
    
    methods
        function [status, cmdout] = runPyTest(testCase, testName)
            tests.util.addFolderToPythonPath( fileparts(mfilename('fullpath')) )
            
            pythonExecutable = getenv("PYTHON_EXECUTABLE");
            cmd = sprintf('"%s" -B -m unittest %s.%s.%s',...
                pythonExecutable,...
                'PyNWBIOTest', testCase.className(), testName);
            [status, cmdout] = system(cmd);
        end
    end
end
