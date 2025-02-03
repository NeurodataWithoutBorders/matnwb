classdef (SharedTestFixtures = {tests.fixtures.NwbTypeGeneratorFixture}) ...        
    dataStubTest < matlab.unittest.TestCase
    
    methods (TestMethodSetup)
        function setupMethod(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testRegionRead(testCase)
        
            nwb = NwbFile(...
                'session_description', 'a test NWB File', ...
                'identifier', 'mouse004_day4', ...
                'session_start_time', datetime(2018, 3, 1, 12, 0, 0, 'TimeZone', 'local'));
            
            data = reshape(1:5000, 25, 5, 4, 2, 5);
            
            timeseries = types.core.TimeSeries(...
                'starting_time', 0.0, ... % seconds
                'starting_time_rate', 200., ... % Hz
                'data', data,...
                'data_unit','na');
            
            nwb.acquisition.set('data', timeseries);
            %%
            
            nwbExport(nwb, 'test_stub_read.nwb');
            nwb2 = nwbRead('test_stub_read.nwb', 'ignorecache');
            
            stub = nwb2.acquisition.get('data').data;
            
            %%
            % test subset/missing dimensions
            stubData = stub(2:4, 2:4, 2:4);
            testCase.verifyEqual(stubData, data(2:4, 2:4, 2:4));
            % test legacy load style
            testCase.verifyEqual(stubData, stub.load([2, 2, 2], [1, 1, 1], [4, 4, 4]));
            testCase.verifyEqual(stubData, stub.load([2, 2, 2], [4, 4, 4]));
            
            % test Inf
            testCase.verifyEqual(stub(2:end, 2:end, 2:end, :), data(2:end, 2:end, 2:end, :));
            
            % test stride
            testCase.verifyEqual(stub(1:2:25, 1:2:4, :, :), data(1:2:25, 1:2:4, :, :));
            
            % test flatten
            testCase.verifyEqual(stub(1, 1, :), data(1, 1, :));
            
            % test non-dangling `:`
            testCase.verifyEqual(stub(:, 1), data(:, 1));
            
            % test arbitrary indices
            primeInd = primes(25);
            testCase.verifyEqual(stub(primeInd), data(primeInd));
            % multidim scalar indices outputs data according to selection orientation.
            testCase.verifyEqual(stub(primeInd .'), data(primeInd .'));
            testCase.verifyEqual(stub(primeInd, 2:4, :), data(primeInd, 2:4, :));
            testCase.verifyEqual(stub(primeInd, :, 1), data(primeInd, :, 1));
            testCase.verifyEqual(stub(primeInd, [1 2 5]), data(primeInd, [1 2 5]));
            testCase.verifyEqual(stub([1 25], [1 5], [1 4], [1 2], [1 5]), data([1 25], [1 5], [1 4], [1 2], [1 5]));
            overflowPrimeInd = primes(31);
            testCase.verifyEqual(stub(overflowPrimeInd), stub(ind2sub(stub.dims, overflowPrimeInd)));
            testCase.verifyEqual(stub(overflowPrimeInd), data(overflowPrimeInd));
            
            % test duplicate indices
            testCase.verifyEqual(stub([1 1 1 1]), data([1 1 1 1]));
            
            % test out of order indices
            testCase.verifyEqual(stub([5 4 3 2 2]), data([5 4 3 2 2]));
        end
        
        function testObjectCopy(testCase)
            import tests.fixtures.ExtensionGenerationFixture

            rootDir = misc.getMatnwbDir();

            testSchemaLocation = fullfile(rootDir, '+tests', 'test-schema');
            typesOutputFolder = testCase.getTypesOutputFolder();

            extensionNamespaceFile = fullfile(testSchemaLocation, 'regionReferenceSchema', 'rrs.namespace.yaml');
            testCase.applyFixture(...
                ExtensionGenerationFixture(extensionNamespaceFile, typesOutputFolder))
            
            extensionNamespaceFile = fullfile(testSchemaLocation, 'compoundSchema', 'cs.namespace.yaml');
            testCase.applyFixture(...
                ExtensionGenerationFixture(extensionNamespaceFile, typesOutputFolder))

            nwb = NwbFile(...
                'identifier', 'DATASTUB',...
                'session_description', 'test datastub object copy',...
                'session_start_time', datetime());
            rc = types.rrs.RefContainer('data', types.rrs.RefData('data', rand(100, 100)));
            rcPath = '/acquisition/rc';
            rcDataPath = [rcPath '/data'];
            rcRef = types.cs.CompoundRefData('data', table(...
                rand(2, 1),...
                rand(2, 1),...
                [types.untyped.ObjectView(rcPath); types.untyped.ObjectView(rcPath)],...
                [types.untyped.RegionView(rcDataPath, 1:2, 99:100); types.untyped.RegionView(rcDataPath, 5:6, 88:89)],...
                'VariableNames', {'a', 'b', 'objref', 'regref'}));
            
            nwb.acquisition.set('rc', rc);
            nwb.analysis.set('rcRef', rcRef);
            nwbExport(nwb, 'original.nwb');
            nwbNew = nwbRead('original.nwb', 'ignorecache');
            tests.util.verifyContainerEqual(testCase, nwbNew, nwb);
            nwbExport(nwbNew, 'new.nwb');
        end
    end

    methods (Access = private)
        function typesOutputFolder = getTypesOutputFolder(testCase)
            F = testCase.getSharedTestFixtures();
            isMatch = arrayfun(@(x) isa(x, 'tests.fixtures.NwbTypeGeneratorFixture'), F);
            F = F(isMatch);
            
            typesOutputFolder = F.TypesOutputFolder;
        end
    end
end
