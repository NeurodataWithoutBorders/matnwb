classdef RoundTripTest < matlab.unittest.TestCase  
  properties
    registry
    file
  end
  
  methods(TestClassSetup)   
    function setupClass(testCase)
      rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
      testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
      corePath = fullfile(rootPath, 'schema', 'core', 'nwb.namespace.yaml');
      testCase.registry = generateCore(corePath);
    end
  end
  
  methods(TestClassTeardown)
    function teardownClass(testCase)
      classes = fieldnames(testCase.registry);
      files = strcat(fullfile('+types', classes), '.m');
      delete(files{:});
    end
  end
  
  methods(TestMethodSetup)
    function setupMethod(testCase)
      testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
      testCase.file = nwbfile( ...
        'source', {'a test source'}, ...
        'session_description', {'a test NWB File'}, ...
        'identifier', {'TEST123'}, ...
        'session_start_time', {datestr([1970, 1, 1, 12, 0, 0], 'yyyy-mm-dd HH:MM:SS')}, ...
        'file_create_date', {datestr([2017, 4, 15, 12, 0, 0], 'yyyy-mm-dd HH:MM:SS')});
      testCase.addContainer(testCase.file);
    end
  end
  
  methods(Test)
    function testRoundTrip(testCase)
      filename = ['MatNWB.' testCase.className() '.testRoundTrip.nwb'];
      nwbExport(testCase.file, filename);
      writeContainer = testCase.getContainer(testCase.file);
      readFile = nwbRead(filename);
      readContainer = testCase.getContainer(readFile);
      testCase.verifyContainerEqual(readContainer, writeContainer);
    end
  end
  
  methods
    function n = className(testCase)
      classSplit = strsplit(class(testCase), '.');
      n = classSplit{end};
    end
    
    function verifyContainerEqual(testCase, actual, expected)
      testCase.verifyEqual(class(actual), class(expected));
      props = properties(actual);
      for i = 1:numel(props)
        prop = props{i};
        val1 = actual.(prop);
        val2 = expected.(prop);
        if isa(val1, 'types.untyped.Group') || isa(val1, 'types.untyped.Link')
          verifyUntypedEqual(testCase, val1, val2);
        elseif isa(val1, 'types.NWBContainer')
          verifyContainerEqual(testCase, val1, val2);
        else
          testCase.verifyEqual(val1, val2, ...
            ['Values for property ''' prop ''' are not equal']);
        end
      end
    end
    
    function verifyUntypedEqual(testCase, actual, expected)
      testCase.verifyEqual(class(actual), class(expected));
      props = properties(actual);
      for i = 1:numel(props)
        prop = props{i};
        val1 = actual.(prop);
        val2 = expected.(prop);
        if isa(val1, 'types.NWBContainer')
          verifyContainerEqual(testCase, val1, val2);
        else
          testCase.verifyEqual(val1, val2, ...
            ['Values for property ''' prop ''' are not equal']);
        end
      end
    end
    
  end
  
  methods(Abstract)
    addContainer(testCase, file);
    c = getContainer(testCase, file);
  end
  
end