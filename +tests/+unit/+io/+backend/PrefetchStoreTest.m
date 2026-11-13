classdef PrefetchStoreTest < matlab.unittest.TestCase
% PrefetchStoreTest - Unit tests for io.backend.zarr3.internal.PrefetchStore.

    properties (Access = private)
        Inner
        Store
    end

    methods (TestClassSetup)
        function setupDependencyPaths(testCase)
            tests.util.assumeZarr3Support(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(...
                tests.util.getZarr3DependencyPaths()));
        end
    end

    methods (TestMethodSetup)
        function createStores(testCase)
            testCase.Inner = zarr.stores.MemoryStore();
            testCase.Inner.set("a", uint8([1 2 3]));
            testCase.Inner.set("b", uint8([4 5]));
            testCase.Store = io.backend.zarr3.internal.PrefetchStore(testCase.Inner);
        end
    end

    methods (Test)
        function prefetchedValuesAnswerReads(testCase)
        % After prefetch, a read comes from the prefetched value, not from
        % the inner store, so a later change to the inner store is not seen.
            testCase.Store.prefetch(["a", "b"]);
            testCase.Inner.set("a", uint8(9));

            [data, found] = testCase.Store.get("a");

            testCase.verifyTrue(found);
            testCase.verifyEqual(data, uint8([1 2 3]));
        end

        function absentKeyIsRememberedAsAbsent(testCase)
            testCase.Store.prefetch("missing");

            [data, found] = testCase.Store.get("missing");

            testCase.verifyFalse(found);
            testCase.verifyEmpty(data);
        end

        function keyNotPrefetchedIsReadFromInnerStore(testCase)
            testCase.Store.prefetch("a");

            [data, found] = testCase.Store.get("b");

            testCase.verifyTrue(found);
            testCase.verifyEqual(data, uint8([4 5]));
        end

        function setReplacesPrefetchedValue(testCase)
            testCase.Store.prefetch("a");

            testCase.Store.set("a", uint8(7));

            testCase.verifyEqual(testCase.Store.get("a"), uint8(7));
        end

        function getManyMixesPrefetchedAndOtherKeys(testCase)
            testCase.Store.prefetch(["a", "missing"]);

            [values, found] = testCase.Store.getMany(["b", "a", "missing"]);

            testCase.verifyEqual(found, [true true false]);
            testCase.verifyEqual(values{1}, uint8([4 5]));
            testCase.verifyEqual(values{2}, uint8([1 2 3]));
        end
    end
end
