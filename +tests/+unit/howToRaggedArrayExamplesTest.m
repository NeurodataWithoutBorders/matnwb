classdef howToRaggedArrayExamplesTest < tests.abstract.NwbTestCase
% howToRaggedArrayExamplesTest - Executes the runnable code embedded in the
% "Storing Ragged and Doubly-Ragged Array Columns" how-to guide, keeping the
% documented snippets correct against the API. The example function contains
% its own assertions.

    methods (Test)
        function testRaggedArrayExamplesRun(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(exampleFolder()));

            % Runs to completion only if every embedded snippet and its
            % assertions pass.
            ragged_arrays_examples();
        end

        function testSnippetsRunWithoutOtherCode(testCase)
            % A reader runs the snippets of the guide from top to bottom,
            % so together they must define every variable they use. The
            % code between the snippet markers is written to a function
            % file, in the order of the example file, and run on its own.
            exampleFile = fullfile(exampleFolder(), 'ragged_arrays_examples.m');
            snippets = regexp(fileread(exampleFile), ...
                '% snippet: \S+[ \t]*\n(.*?)\n[ \t]*% end snippet', 'tokens');
            testCase.assertNotEmpty(snippets, 'No snippets found in the example file.');
            snippetCode = cellfun(@(token) token{1}, snippets, 'UniformOutput', false);

            % Inside a function the snippets see no other variables, so a
            % snippet that relies on code outside the snippets fails with an
            % undefined variable.
            functionName = 'raggedArraySnippets';
            temporaryFolder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture);
            fileId = fopen(fullfile(temporaryFolder.Folder, [functionName, '.m']), 'w');
            fprintf(fileId, 'function %s()\n', functionName);
            fprintf(fileId, '%s\n', snippetCode{:});
            fprintf(fileId, 'end\n');
            fclose(fileId);
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture(temporaryFolder.Folder));

            runSnippets = str2func(functionName);
            runSnippets();
        end
    end
end

function folder = exampleFolder()
    folder = fullfile(misc.getMatnwbDir(), 'docs', 'source', 'pages', 'how_to', 'examples');
end
