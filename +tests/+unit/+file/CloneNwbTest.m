classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
    CloneNwbTest < matlab.unittest.TestCase

    methods (TestClassSetup)
        function setupClass(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testCloneNwbFile(testCase)
            % Create a superclass
            superClassDef = [...
                'classdef MyCustomNwbFile < types.core.NWBFile\n', ...
                '    methods\n', ...
                '        function sayHello(obj)\n', ...
                '            fprintf(''Hello %%s\\n'', obj.general_experimenter)\n', ...
                '        end\n', ...
                '    end\n', ...
                'end\n'];
            fid = fopen('MyCustomNwbFile.m', 'w');
            fprintf(fid, superClassDef);
            fclose(fid);

            currentClassDef = fileread(fullfile(misc.getMatnwbDir(), 'NwbFile.m'));
            cleanupObj = onCleanup(@(classDefStr) restoreNwbFileClass(currentClassDef));
            
            file.cloneNwbFileClass(fullfile('NwbFile'), 'MyCustomNwbFile')

            testCase.verifyTrue( isfile(fullfile(misc.getMatnwbDir(), 'NwbFile.m')) )

            nwbFile = NwbFile();
            nwbFile.general_experimenter = "Mouse McMouse";
            C = evalc('nwbFile.sayHello()');
            testCase.verifyEqual(C, sprintf('Hello Mouse McMouse\n'));
        end
    end
end

function restoreNwbFileClass(classDefStr)
    fid = fopen( fullfile(misc.getMatnwbDir(), 'NwbFile.m'), 'wt' );
    fwrite(fid, classDefStr);
    fclose(fid);
end