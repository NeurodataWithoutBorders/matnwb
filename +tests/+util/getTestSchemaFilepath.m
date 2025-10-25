function filePath = getTestSchemaFilepath(schemaName)
% getTestSchemaFilepath - Retrieves the file path for the specified test schema.
% 
% Syntax:
%   filePath = getTestSchemaFilepath(schemaName) retrieves the full file path
%   to the test schema namespace file corresponding to the provided schema name.
% 
% Input Arguments:
%   schemaName (1,1) string - The name of the schema for which the file path
%   is to be retrieved.
% 
% Output Arguments:
%   filePath - The full file path to the specified test schema namespace file.

    arguments
        schemaName (1,1) string
    end

    testSchemaRoot = fullfile(misc.getMatnwbDir, '+tests', 'test-schema');
    expectedFilename = sprintf('%s.namespace.yaml', schemaName);

    L = dir(fullfile(testSchemaRoot, '**', expectedFilename));

    assert(~isempty(L), ...
        'NWB:Test:TestSchemaNotFound', ...
        'No test schema namespace found for name "%s"', schemaName)

    assert(isscalar(L), ...
        'NWB:Test:MultipleTestSchemasFound', ...
        ['Expected to find exactly one schema namespace for name "%s", ', ...
        'but found %d.'], schemaName, numel(L))
    
    filePath = fullfile(L(1).folder, L(1).name);
end
