classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
        SchemaRelativePathsTest < matlab.unittest.TestCase
% SchemaRelativePathsTest - Tests for the SchemaRelativePaths constant of generated classes.
%
% file.fillClass lists, per generated class, the schema path of each
% property holding a plain value. HERD writes this path as relative_path,
% so it must match the path HDMF computes from the same schema.

    properties (TestParameter)
        Namespace = {'core', 'hdmf_common', 'hdmf_experimental'}
    end

    methods (Test)
        function testEveryPathFlattensToAPropertyOfItsClass(testCase, Namespace)
            % HERDBase.resolveTarget finds a path by replacing "/" with "_",
            % so every listed path must name a property that way.
            classList = meta.package.fromName(['types.', Namespace]).ClassList;
            for iClass = 1:numel(classList)
                className = classList(iClass).Name;
                relativePaths = testCase.collectPaths(className);
                propertyNames = string({classList(iClass).PropertyList.Name});
                schemaNameMapping = io.internal.getSchemaPropertyNameMapping(className);
                for iPath = 1:numel(relativePaths)
                    schemaName = strrep(relativePaths(iPath), "/", "_");
                    propertyName = io.internal.getPropertyNameForSchemaName( ...
                        schemaNameMapping, char(schemaName));
                    testCase.verifyTrue(ismember(string(propertyName), propertyNames), ...
                        sprintf('Path "%s" of %s does not name a property.', ...
                        relativePaths(iPath), className))
                end
            end
        end

        function testPathsOfPlainValues(testCase)
            testCase.verifyTrue(all(ismember( ...
                ["description", "data", "data/unit", "starting_time/rate"], ...
                testCase.collectPaths('types.core.TimeSeries'))))
            testCase.verifyTrue(all(ismember( ...
                ["session_description", "general/experimenter", "general/intracellular_ephys/filtering"], ...
                testCase.collectPaths('types.core.NWBFile'))))
            testCase.verifyTrue(ismember("species", testCase.collectPaths('types.core.Subject')))
        end

        function testInheritedPathsAreIncluded(testCase)
            testCase.verifyTrue(all(ismember( ...
                ["data/unit", "channel_conversion"], ...
                testCase.collectPaths('types.core.ElectricalSeries'))))
        end

        function testPathsExcludeNeurodataTypes(testCase)
            % Neurodata types, links and sets of typed objects are referenced
            % as objects, so they have no relative path.
            nwbFilePaths = testCase.collectPaths('types.core.NWBFile');
            testCase.verifyFalse(any(ismember( ...
                ["general/subject", "acquisition", "general/devices"], nwbFilePaths)))
            testCase.verifyFalse(ismember("electrodes", ...
                testCase.collectPaths('types.core.ElectricalSeries')))
        end

        function testPathsExcludeValuesNestedInANeurodataType(testCase)
            % Units.spike_times is a VectorData, so its resolution attribute
            % belongs to that VectorData and not to Units.
            unitsPaths = testCase.collectPaths('types.core.Units');
            testCase.verifyFalse(any(ismember( ...
                ["spike_times", "spike_times/resolution", "waveforms/unit"], unitsPaths)))
        end
    end

    methods (Static, Access = private)
        function relativePaths = collectPaths(className)
            relativePaths = matnwb.neurodata.internal.collectConstantPropertiesAcrossHierarchy( ...
                className, 'SchemaRelativePaths');
        end
    end
end
