classdef NwbTestInterface < matlab.unittest.TestCase
    properties
        %     registry
        file
        root;
    end
    
    methods (TestClassSetup)
        function setupClass(testCase)
            rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
            testCase.root = rootPath;
        end
    end
    
    methods (TestMethodSetup)
        function setupMethod(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            generateCore('savedir', '.');
            testCase.file = NwbFile( ...
                'session_description', 'a test NWB File', ...
                'identifier', 'TEST123', ...
                'session_start_time', '2018-12-02T12:57:27.371444-08:00', ...
                'file_create_date', '2017-04-15T12:00:00.000000-08:00',...
                'timestamps_reference_time', '2018-12-02T12:57:27.371444-08:00');
            testCase.addContainer(testCase.file);
        end
    end
    
    methods
        function n = className(testCase)
            classSplit = strsplit(class(testCase), '.');
            n = classSplit{end};
        end    
    end
    
    methods(Abstract)
        addContainer(testCase, file);
        c = getContainer(testCase, file);
    end
end

