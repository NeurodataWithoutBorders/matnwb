classdef LazyArraySelectionTest < matlab.unittest.TestCase
% LazyArraySelectionTest - Tests for how io.backend.base.LazyArray serves subscripts.
%
% The lazy arrays here are in-memory fakes, read in MatNWB's order or in
% reversed storage order. Either way a selection must give what MATLAB
% indexing gives on the same array.

    properties (TestParameter)
        IsStorageOrderReversed = {false, true}
        VolumeSelection = struct( ...
            'wholeColumn', {{':'}}, ...
            'oneElement', {{2, 3, 1}}, ...
            'repeatedRowsBeforeFoldedColon', {{[3 1 3], ':'}}, ...
            'repeatedMiddleIndices', {{':', [5 2 2], ':'}}, ...
            'unsortedInEveryDimension', {{[4 1], [2 3], [3 1]}}, ...
            'firstPlaneByOmission', {{1:2, 2:4}}, ...
            'linearRow', {{[7 3 3 20]}}, ...
            'linearColumn', {{[7; 3]}}, ...
            'linearEmpty', {{[]}})
        VectorSelection = struct( ...
            'repeated', {{[3 1 3]}}, ...
            'contiguous', {{2:5}}, ...
            'whole', {{':'}})
    end

    properties (Constant)
        Volume = reshape(1:60, [4 5 3])
        Vector = (11:20)'
    end

    methods (Test)
        function selectionFromVolumeMatchesIndexing(testCase, IsStorageOrderReversed, VolumeSelection)
            lazyArray = tests.unit.io.backend.doubles.MemoryLazyArrayFake( ...
                testCase.Volume, IsStorageOrderReversed=IsStorageOrderReversed);

            testCase.verifyEqual(lazyArray.load_mat_style(VolumeSelection{:}), ...
                testCase.Volume(VolumeSelection{:}));
        end

        function selectionFromVectorMatchesIndexing(testCase, IsStorageOrderReversed, VectorSelection)
            lazyArray = tests.unit.io.backend.doubles.MemoryLazyArrayFake( ...
                testCase.Vector, IsStorageOrderReversed=IsStorageOrderReversed);

            testCase.verifyEqual(lazyArray.load_mat_style(VectorSelection{:}), ...
                testCase.Vector(VectorSelection{:}));
        end

        function noSubscriptsReadsWholeDataset(testCase, IsStorageOrderReversed)
            lazyArray = tests.unit.io.backend.doubles.MemoryLazyArrayFake( ...
                testCase.Volume, IsStorageOrderReversed=IsStorageOrderReversed);

            testCase.verifyEqual(lazyArray.load_mat_style(), testCase.Volume);
        end

        function filledBoundingBoxIsReadInOneRead(testCase)
            lazyArray = tests.unit.io.backend.doubles.MemoryLazyArrayFake(testCase.Vector);

            lazyArray.load_mat_style([6 3 4 5]);

            testCase.verifyEqual(lazyArray.NumSubscriptReads, 1);
            testCase.verifyEqual(lazyArray.NumPointReads, 0);
        end

        function scatteredLinearSelectionIsReadAsPoints(testCase)
            lazyArray = tests.unit.io.backend.doubles.MemoryLazyArrayFake(testCase.Vector);

            values = lazyArray.load_mat_style([9 2]);

            testCase.verifyEqual(values, testCase.Vector([9 2]));
            testCase.verifyEqual(lazyArray.NumSubscriptReads, 0);
            testCase.verifyEqual(lazyArray.NumPointReads, 1);
        end

        function overreadLimitAllowsLargerBoundingBox(testCase)
            % The box spanning indices 2 and 9 holds 8 elements, four
            % times the selection.
            lazyArray = tests.unit.io.backend.doubles.MemoryLazyArrayFake( ...
                testCase.Vector, MaxBoundingBoxOverread=4);

            values = lazyArray.load_mat_style([9 2]);

            testCase.verifyEqual(values, testCase.Vector([9 2]));
            testCase.verifyEqual(lazyArray.NumSubscriptReads, 1);
            testCase.verifyEqual(lazyArray.NumPointReads, 0);
        end

        function pointsAreReadInStorageOrder(testCase)
            % Elements of a reversed volume are found only when their
            % subscripts are reversed too.
            lazyArray = tests.unit.io.backend.doubles.MemoryLazyArrayFake( ...
                testCase.Volume, IsStorageOrderReversed=true);

            values = lazyArray.load_mat_style([60 1 37]);

            testCase.verifyEqual(values, testCase.Volume([60 1 37]));
            testCase.verifyEqual(lazyArray.NumPointReads, 1);
        end

        function invalidSubscriptsAreRejected(testCase)
            lazyArray = tests.unit.io.backend.doubles.MemoryLazyArrayFake(testCase.Volume);

            testCase.verifyError(@() lazyArray.load_mat_style(1, 1, 1, 1), ...
                'NWB:DataStub:Load:TooManyDimensions');
            testCase.verifyError(@() lazyArray.load_mat_style(1.5), ...
                'NWB:DataStub:Load:InvalidSelection');
            testCase.verifyError(@() lazyArray.load_mat_style(5, 1), ...
                'NWB:DataStub:Load:InvalidSelection');
            testCase.verifyError(@() lazyArray.load_mat_style(61), ...
                'NWB:DataStub:Load:InvalidSelection');
        end
    end
end
