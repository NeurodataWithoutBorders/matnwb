classdef SpaceTest < matlab.unittest.TestCase
% SpaceTest - Unit test for io.space.* namespace.

    methods (Test)
        function testEmptyInput(testCase)
            shape = io.space.findShapes([]);

            testCase.verifyClass(shape, 'cell')
            testCase.verifyLength(shape, 1)
            testCase.verifyClass(shape{1}, 'io.space.shape.Block')
            testCase.verifyEqual(shape{1}.length, 0)
        end

        function testSingleElement(testCase)
            shapes = io.space.findShapes(7);

            testCase.verifyLength(shapes, 1)
            testCase.verifyClass(shapes{1}, 'io.space.shape.Point')
            testCase.verifyEqual(shapes{1}.index, 7)
        end

        function testContiguousRunsBecomeOneBlockEach(testCase)
            shapes = io.space.findShapes([1:5, 10:12, 20:30]);

            testCase.verifyEqual(cellfun(@class, shapes, 'UniformOutput', false), ...
                repmat({'io.space.shape.Block'}, 1, 3))
            testCase.verifyEqual(getBlockSpecs(shapes), [1 1 5; 10 1 12; 20 1 30])
        end

        function testPureStrideBecomesOneStridedBlock(testCase)
            shapes = io.space.findShapes(1:2:99);

            testCase.verifyLength(shapes, 1)
            testCase.verifyEqual(getBlockSpecs(shapes), [1 2 99])
        end

        function testStrideWithExtraIndexKeepsStridedBlock(testCase)
            shapes = io.space.findShapes([1:2:99, 4]);

            testCase.verifyLength(shapes, 2)
            testCase.verifyEqual(getBlockSpecs(shapes(1)), [1 2 99])
            testCase.verifyClass(shapes{2}, 'io.space.shape.Point')
            testCase.verifyEqual(shapes{2}.index, 4)
        end

        function testRunsAndIsolatedIndices(testCase)
            shapes = io.space.findShapes([1:5, 8, 10:12, 20]);

            testCase.verifyEqual(cellfun(@class, shapes, 'UniformOutput', false), ...
                {'io.space.shape.Block', 'io.space.shape.Point', ...
                'io.space.shape.Block', 'io.space.shape.Point'})
            testCase.verifyEqual(getBlockSpecs(shapes([1 3])), [1 1 5; 10 1 12])
            testCase.verifyEqual([shapes{2}.index, shapes{4}.index], [8 20])
        end

        function testUnsortedInputWithDuplicates(testCase)
            shapes = io.space.findShapes([12 10 1 2 3 11 3]');

            testCase.verifyEqual(getBlockSpecs(shapes), [1 1 3; 10 1 12])
        end

        function testIrregularIndicesBecomeOneShapePerRun(testCase)
            % Scattered indices with irregular gaps have no stride worth a
            % strided block, so each run of consecutive indices is selected
            % on its own.
            rng(1)
            indices = sort(randperm(50000, 1000));
            numRuns = sum(diff(indices) > 1) + 1;

            shapes = io.space.findShapes(indices);

            testCase.verifyLength(shapes, numRuns)
            testCase.verifyEqual(getSelectedIndices(shapes), indices)
            isBlock = cellfun(@(shape) isa(shape, 'io.space.shape.Block'), shapes);
            testCase.verifyTrue(all(cellfun(@(shape) shape.step == 1, shapes(isBlock))))
        end

        function testManyRunsSelectExactlyTheInput(testCase)
            % Runs of 1 to 8 indices with gaps of 1 to 20 between them.
            rng(2)
            numRuns = 10000;
            runLengths = randi([1 8], 1, numRuns);
            runStarts = cumsum(randi([1 20], 1, numRuns) + [0, runLengths(1:end-1)]);
            indices = arrayfun(@(s, l) s:(s + l - 1), runStarts, runLengths, 'UniformOutput', false);
            indices = [indices{:}];

            shapes = io.space.findShapes(indices);

            testCase.verifyLength(shapes, numRuns)
            testCase.verifyEqual(getSelectedIndices(shapes), indices)
        end

        function testSegmentSelection(testCase)
            shape = io.space.segmentSelection({1:10}, [1,100]);
            
            testCase.verifyClass(shape, 'cell')
        end

        function testPoint(testCase)
            point = io.space.shape.Point(1);
            
            testCase.verifyEqual(point.getMatlabIndex, 1)
        end
    end 
end

function specs = getBlockSpecs(shapes)
% getBlockSpecs - One row [start step stop] per Block in shapes.
specs = cell2mat(cellfun(@(shape) [shape.start, shape.step, shape.stop], shapes(:), 'UniformOutput', false));
end

function indices = getSelectedIndices(shapes)
% getSelectedIndices - Sorted union of the indices the shapes select.
indices = cell(size(shapes));
for iShape = 1:numel(shapes)
    if isa(shapes{iShape}, 'io.space.shape.Point')
        indices{iShape} = shapes{iShape}.index;
    else
        indices{iShape} = shapes{iShape}.range;
    end
end
indices = sort([indices{:}]);
end
