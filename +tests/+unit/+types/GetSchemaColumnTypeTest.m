classdef GetSchemaColumnTypeTest < matlab.unittest.TestCase
% GetSchemaColumnTypeTest - Unit tests for
% types.util.dynamictable.internal.getSchemaColumnType, which reads the
% class of a column from the DeclaredSchemaColumnTypes constant of a table
% class and its superclasses.

    methods (Test)
        function testReturnsClassListedByTableClass(testCase)
            tableStub = tests.unit.types.doubles.TableStubWithColumnTypes();

            columnClassName = types.util.dynamictable.internal.getSchemaColumnType( ...
                tableStub, 'parentColumn');

            testCase.verifyEqual(columnClassName, 'parent.ColumnClass')
        end

        function testReturnsClassListedBySuperclass(testCase)
            tableStub = tests.unit.types.doubles.TableStubWithInheritedColumnTypes();

            columnClassName = types.util.dynamictable.internal.getSchemaColumnType( ...
                tableStub, 'parentColumn');

            testCase.verifyEqual(columnClassName, 'parent.ColumnClass')
        end

        function testReturnsClassListedBySubclass(testCase)
            tableStub = tests.unit.types.doubles.TableStubWithInheritedColumnTypes();

            columnClassName = types.util.dynamictable.internal.getSchemaColumnType( ...
                tableStub, 'childColumn');

            testCase.verifyEqual(columnClassName, 'child.ColumnClass')
        end

        function testSubclassTakesPrecedenceOverSuperclass(testCase)
            tableStub = tests.unit.types.doubles.TableStubWithInheritedColumnTypes();

            columnClassName = types.util.dynamictable.internal.getSchemaColumnType( ...
                tableStub, 'sharedColumn');

            testCase.verifyEqual(columnClassName, 'child.SharedColumnClass')
        end

        function testReturnsEmptyForUnlistedColumn(testCase)
            tableStub = tests.unit.types.doubles.TableStubWithInheritedColumnTypes();

            columnClassName = types.util.dynamictable.internal.getSchemaColumnType( ...
                tableStub, 'unlistedColumn');

            testCase.verifyEmpty(columnClassName)
        end

        function testReturnsEmptyForClassWithoutColumnTypes(testCase)
            objectWithoutColumnTypes = containers.Map();

            columnClassName = types.util.dynamictable.internal.getSchemaColumnType( ...
                objectWithoutColumnTypes, 'anyColumn');

            testCase.verifyEmpty(columnClassName)
        end
    end
end
