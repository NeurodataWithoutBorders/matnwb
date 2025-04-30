classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...        
    untypedSetTest < matlab.unittest.TestCase
    
    methods (TestMethodSetup)
        function setupMethod(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end
    
    methods (Test)
        function testCreateSetWithFunctionInput(testCase)
            set = types.untyped.Set(@(key, value) true);
            testCase.verifyNotEmpty(set.ValidationFcn)
        end
        
        function testCreateSetFromStruct(testCase)
            untypedSet = types.untyped.Set( struct('a',1, 'b', 2) );
            testCase.verifyEqual(untypedSet.get('a'), 1)
        end
        
        function testCreateSetFromNvPairs(testCase)
            untypedSet = types.untyped.Set( 'a',1, 'b', 2 );
            testCase.verifyEqual(untypedSet.get('a'), 1)
        end
        
        function testCreateSetFromNvPairsPlusFunctionHandle(testCase)
            untypedSet = types.untyped.Set( 'a',1, 'b', 2, @(key, value) disp('Hello World'));
            testCase.verifyEqual(untypedSet.get('a'), 1)
        end
        
        function testDisplayEmptyObject(testCase)
            emptyUntypedSet = types.untyped.Set(); %#ok<NASGU>
            C = evalc( 'disp(emptyUntypedSet)' );
            testCase.verifyClass(C, 'char')
        end
        
        function testDisplayScalarObject(testCase)
            scalarSet = types.untyped.Set('a', 1); %#ok<NASGU>
            C = evalc( 'disp(scalarSet)' );
            testCase.verifyClass(C, 'char')
        end
        
        function testGetSetSize(testCase)
            untypedSet = types.untyped.Set( 'a',1, 'b', 2 );
            
            [nRowsA, nColsA] = size(untypedSet);
        
             nRowsB = size(untypedSet, 1);
             nColsB = size(untypedSet, 2);
        
             testCase.verifyEqual(nRowsA, nRowsB);
             testCase.verifyEqual(nColsA, nColsB);
        end
        
        function testHorizontalConcatenation(testCase)
            untypedSetA = types.untyped.Set( struct('a',1, 'b', 2) );
            untypedSetB = types.untyped.Set( struct('c',3, 'd', 3) );
        
            testCase.verifyError(@() [untypedSetA, untypedSetB], 'NWB:Set:Unsupported') 
        end
        
        function testVerticalConcatenation(testCase)
            untypedSetA = types.untyped.Set( struct('a',1, 'b', 2) );
            untypedSetB = types.untyped.Set( struct('c',3, 'd', 3) );
        
            testCase.verifyError(@() [untypedSetA; untypedSetB], 'NWB:Set:Unsupported') 
        end
        
        function testSetCharValue(testCase)
            untypedSet = types.untyped.Set( struct('a', 'a', 'b', 'b') );
            untypedSet.set('c', 'c');
            testCase.verifyEqual(untypedSet.get('c'), 'c')
        end
    end
end
