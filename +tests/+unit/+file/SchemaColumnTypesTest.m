classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
        SchemaColumnTypesTest < matlab.unittest.TestCase
% SchemaColumnTypesTest - Tests for the DeclaredSchemaColumnTypes constant of generated classes.
%
% file.fillClass lists, per generated DynamicTable class, the class of each
% column that the schema declares as a subtype of VectorData. addRow reads
% the list to create a column of that class when the first row is added.

    properties (TestParameter)
        Namespace = {'core', 'hdmf_common', 'hdmf_experimental'}
    end

    methods (Test)
        function testEveryListedColumnIsATypedPropertyOfItsClass(testCase, Namespace)
            classList = meta.package.fromName(['types.', Namespace]).ClassList;
            for iClass = 1:numel(classList)
                className = classList(iClass).Name;
                columnTypes = testCase.readOwnColumnTypes(className);
                if isempty(columnTypes)
                    continue
                end

                propertyNames = {classList(iClass).PropertyList.Name};
                columnNames = fieldnames(columnTypes);
                for iColumn = 1:numel(columnNames)
                    columnName = columnNames{iColumn};
                    columnClass = meta.class.fromName(columnTypes.(columnName));

                    testCase.verifyTrue(ismember(columnName, propertyNames), ...
                        sprintf('Column "%s" of %s does not name a property.', ...
                        columnName, className))
                    testCase.verifyTrue(columnClass < ?types.hdmf_common.VectorData, ...
                        sprintf('Column "%s" of %s is not a subtype of VectorData.', ...
                        columnName, className))
                    testCase.verifyFalse(columnClass <= ?types.hdmf_common.VectorIndex, ...
                        sprintf('Column "%s" of %s is a VectorIndex.', ...
                        columnName, className))
                end
            end
        end

        function testTypedColumnsAreListed(testCase)
            testCase.verifyEqual( ...
                testCase.readOwnColumnTypes('types.core.IntracellularStimuliTable'), ...
                struct( ...
                    'stimulus', 'types.core.TimeSeriesReferenceVectorData', ...
                    'stimulus_template', 'types.core.TimeSeriesReferenceVectorData'))
            testCase.verifyEqual( ...
                testCase.readOwnColumnTypes('types.core.TimeIntervals'), ...
                struct('timeseries', 'types.core.TimeSeriesReferenceVectorData'))
        end

        function testRegionColumnsAreListed(testCase)
            testCase.verifyEqual( ...
                testCase.readOwnColumnTypes('types.core.Units'), ...
                struct('electrodes', 'types.hdmf_common.DynamicTableRegion'))
        end

        function testClassWithPlainColumnsListsNone(testCase)
            % The schema-defined columns of PlaneSegmentation are plain
            % VectorData and VectorIndex.
            testCase.verifyEmpty( ...
                testCase.readOwnColumnTypes('types.core.PlaneSegmentation'))
        end
    end

    methods (Static, Access = private)
        function columnTypes = readOwnColumnTypes(className)
            % The struct listed by the class itself, or [] if it lists none.
            columnTypes = [];
            metaClass = meta.class.fromName(className);
            propertyList = metaClass.PropertyList;
            isDeclaration = strcmp({propertyList.Name}, 'DeclaredSchemaColumnTypes') ...
                & [propertyList.DefiningClass] == metaClass;
            if any(isDeclaration)
                columnTypes = propertyList(isDeclaration).DefaultValue;
            end
        end
    end
end
