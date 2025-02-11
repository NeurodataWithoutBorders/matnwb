classdef GenerateSpecificationMixin < matlab.unittest.TestCase
    methods (Access = protected)
        function typesOutputFolder = getTypesOutputFolder(testCase)
            F = testCase.getSharedTestFixtures();
            isMatch = arrayfun(@(x) isa(x, 'tests.fixtures.GenerateCoreFixture'), F);
            F = F(isMatch);
            
            typesOutputFolder = F.TypesOutputFolder;
        end
    end
end