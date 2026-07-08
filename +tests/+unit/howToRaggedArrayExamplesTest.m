classdef howToRaggedArrayExamplesTest < tests.abstract.NwbTestCase
% howToRaggedArrayExamplesTest - Executes the runnable code embedded in the
% "Storing Ragged and Doubly-Ragged Array Columns" how-to guide, keeping the
% documented snippets correct against the API. The example function contains
% its own assertions.

    methods (Test)
        function testRaggedArrayExamplesRun(testCase)
            exampleDir = fullfile(misc.getMatnwbDir(), ...
                'docs', 'source', 'pages', 'how_to', 'examples');
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(exampleDir));

            % Runs to completion only if every embedded snippet and its
            % assertions pass.
            ragged_arrays_examples();
        end
    end
end
