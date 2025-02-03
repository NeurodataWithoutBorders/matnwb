classdef (Abstract, SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...        
    SchemaTest < matlab.unittest.TestCase
% SCHEMATEST - Abstract class for generating and testing test-schemas.
%
%   Subclasses must implement the abstract properties:
%       - SchemaFolder
%       - SchemaNamespaceFileName
%
%   Example subclasses are found in the "tests.unit.schema" namespace
%
%   See also: matlab.unittest.TestCase, tests.fixtures.GenerateCoreFixture
    
    properties (Constant, Abstract)
        SchemaFolder % Name of folder containing the schema definition files
        SchemaNamespaceFileName % The filename of the specification's namespace file
    end

    properties (Constant)
        % SchemaRootDirectory - Root directory for test schemas
        SchemaRootDirectory = fullfile(misc.getMatnwbDir(), '+tests', 'test-schema')
    end

    methods (TestClassSetup)
        function setup(testCase)
            % SETUP Performs fixture setup at the class level

            import tests.fixtures.ExtensionGenerationFixture

            F = testCase.getSharedTestFixtures();
            isMatch = arrayfun(@(x) isa(x, 'tests.fixtures.GenerateCoreFixture'), F);
            F = F(isMatch);
            
            typesOutputFolder = F.TypesOutputFolder;

            namespaceFilePath = fullfile( ...
                testCase.SchemaRootDirectory, ...
                testCase.SchemaFolder, ...
                testCase.SchemaNamespaceFileName);

            testCase.applyFixture( ...
                ExtensionGenerationFixture(namespaceFilePath, typesOutputFolder) )
        end
    end

    methods (TestMethodSetup)
        function setupMethod(testCase)
            % SETUPMETHOD Applies a WorkingFolderFixture before each test
            %   Ensures every test method runs in its own temporary working folder
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end
end
