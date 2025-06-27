classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
        HasUnnamedGroupsTest < matlab.unittest.TestCase
    % HASUNNAMEDGROUPSTEST Tests for the HasUnnamedGroups mixin
    %
    % This test suite verifies the functionality of the HasUnnamedGroups mixin,
    % which is used to simplify access to unnamed subgroup Sets.
    % It uses types.core.ProcessingModule as a test type because it's the only
    % NWB type that has two groups.
    
    methods (Test)
        function testAddRemove(testCase)
            % Test add and remove methods of HasUnnamedGroups mixin
            
            % Create a ProcessingModule
            module = types.core.ProcessingModule();
            
            % Add a new type using the mixin's add method
            module.add('TimeSeries', types.core.TimeSeries());
            
            % Verify that the dynamic property was created
            testCase.verifyTrue(isprop(module, 'TimeSeries'), ...
                'Dynamic property was not created');
            
            % Verify that the dynamic property returns the correct value
            testCase.verifyClass(module.TimeSeries, ...
                'types.core.TimeSeries', ...
                'Dynamic property returned incorrect value');
            
            % Verify that object is present on the nwbdatainterface property
            testCase.verifyTrue(module.nwbdatainterface.isKey('TimeSeries'))

            % Remove the item and verify it's gone
            module.remove('TimeSeries');
            testCase.verifyFalse(isprop(module, 'TimeSeries'), ...
                'Dynamic property was not removed');

            % Verify that object is also removed from the nwbdatainterface
            % property
            testCase.verifyFalse(module.nwbdatainterface.isKey('TimeSeries'))
        end
        
        function testGet(testCase)
            % Create a ProcessingModule
            module = types.core.ProcessingModule();
            
            % Add items with the same name to different groups
            module.nwbdatainterface.set('TimeSeries', types.core.TimeSeries());
            module.dynamictable.set('DynamicTable', types.hdmf_common.DynamicTable());

            timeSeries = module.get('TimeSeries');
            testCase.verifyClass(timeSeries, 'types.core.TimeSeries')

            dynamicTable = module.get('DynamicTable');
            testCase.verifyClass(dynamicTable, 'types.hdmf_common.DynamicTable')
        
            testCase.verifyError(...
                @() module.get('NonExistingName'), ...
                'NWB:HasUnnamedGroupsMixin:ObjectDoesNotExist')
        end

        function testLegacySyntax(testCase)
            % Create a ProcessingModule
            module = types.core.ProcessingModule();
            
            % Add a new type using the Set interface
            module.nwbdatainterface.set('TimeSeries', types.core.TimeSeries());
            
            % Verify that the dynamic property was created
            testCase.verifyTrue(isprop(module, 'TimeSeries'), ...
                'Dynamic property was not created');
            
            % Verify that the dynamic property returns the correct value
            testCase.verifyClass(module.TimeSeries, ...
                'types.core.TimeSeries', ...
                'Dynamic property returned incorrect value');
            
            % Remove the item and verify it's gone
            module.nwbdatainterface.remove('TimeSeries');
            testCase.verifyFalse(isprop(module, 'TimeSeries'), ...
                'Dynamic property was not removed');
        end

        function testInvalidMatlabName(testCase)
            % Create a ProcessingModule
            module = types.core.ProcessingModule();
            
            % Add items with similar names to nwbdatainterface            
            module.add('Time-Series', types.core.TimeSeries())

            % Verify that the dynamic property was created and accessible
            % with a valid MATLAB name
            testCase.verifyTrue(isprop(module, 'Time_Series'), ...
                'Dynamic property was not created');

            testCase.verifyClass(module.Time_Series, ...
                'types.core.TimeSeries', ...
                'Dynamic property returned incorrect value');
        end

        function testSimilarNames(testCase)
            % Test handling of similar names that result in the same valid name

            % Create a ProcessingModule
            module = types.core.ProcessingModule();

            % Add items with similar names to nwbdatainterface
            module.add('Time_Series', types.core.TimeSeries())

            % todo: Set needs to support names that will have the same alias
            module.add('Time-Series', types.core.TimeSeries())

            % Verify that the dynamic property was created
            testCase.verifyTrue(isprop(module, 'Time_Series'), ...
                'Dynamic property was not created');

            % Verify that similarly named property was created
            testCase.verifyTrue(isprop(module, 'Time_Series_1'), ...
                'Dynamic property was not created');
        end
        
        function testCrossGroupNameConflicts(testCase)
            % Test handling of name conflicts across different groups
            
            % Create a ProcessingModule
            module = types.core.ProcessingModule();
            
            % Add items with the same name to different groups
            module.nwbdatainterface.set('Test', types.core.TimeSeries());

            testCase.verifyError(...
                @() module.dynamictable.set('Test', types.hdmf_common.DynamicTable()), ...
                'NWB:HasUnnamedGroupsMixin:DynamicPropertyExists' );
            
            % % Verify both properties exist with appropriate names
            % % One should be Test and the other should have the group name prepended
            % testCase.verifyTrue(isprop(module, 'Test'), ...
            %     'Dynamic property Test was not created');
            % testCase.verifyTrue(isprop(module, 'dynamictable_Test'), ...
            %     'Dynamic property dynamictable_Test was not created');
            
            % Verify the properties return the correct values
            % if isa(module.Test, 'types.core.TimeSeries')
            %     testCase.verifyClass(module.Test, 'types.core.TimeSeries', ...
            %         'Dynamic property Test returned incorrect value');
            %     testCase.verifyClass(module.dynamictable_Test, 'types.hdmf_common.DynamicTable', ...
            %         'Dynamic property dynamictable_Test returned incorrect value');
            % else
            %     testCase.verifyClass(module.Test, 'types.hdmf_common.DynamicTable', ...
            %         'Dynamic property Test returned incorrect value');
            %     testCase.verifyClass(module.nwbdatainterface_Test, 'types.core.TimeSeries', ...
            %         'Dynamic property nwbdatainterface_Test returned incorrect value');
            % end
        end

        function testAddWithExistingName(testCase)
            % Create a ProcessingModule
            module = types.core.ProcessingModule();

            module.add('TimeSeries', types.core.TimeSeries())

            % Adding a new object with the same name should fail
            testCase.verifyError(...
                @() module.add('TimeSeries', types.core.TimeSeries()), ...
                'NWB:HasUnnamedGroupsMixin:KeyExists')
        end
        
        function testOverriding(testCase)
            % Test overriding an existing item
            
            % Create a ProcessingModule
            module = types.core.ProcessingModule();
            
            % Add an item
            module.nwbdatainterface.set('Test', types.core.TimeSeries());
            testCase.verifyTrue(isprop(module, 'Test'), 'Dynamic property Test was not created');
            testCase.verifyClass(module.Test, 'types.core.TimeSeries', ...
                'Dynamic property Test did not return expected value');

            % Override it with a different type
            module.nwbdatainterface.set('Test', types.core.Fluorescence());

            % Verify the property has the new type
            testCase.verifyClass(module.Test, 'types.core.Fluorescence', ...
                'Dynamic property Test did not return the overridden value');
        end

        function testInvalidType(testCase)
            module = types.core.ProcessingModule();
            
            testCase.verifyError(...
                @() module.add('Device', types.core.Device()), ...
                'NWB:HasUnnamedGroupsMixin:AddInvalidType')
        end

        function testObjectDisplay(testCase)
            % Create a ProcessingModule
            module = types.core.ProcessingModule();
            
            % Add one object to each of the subgroups
            module.add('TimeSeries', types.core.TimeSeries());
            module.add('DynamicTable', types.hdmf_common.DynamicTable());

            origPrefValue = getpref('matnwb', 'displaymode', 'flat');
            testCase.addTeardown(@() setpref('matnwb', 'displaymode', origPrefValue))

            setpref('matnwb', 'displaymode', 'flat')
            C = evalc('disp(module)');
            testCase.verifyTrue(contains(C, 'TimeSeries:'))
            testCase.verifyTrue(contains(C, 'DynamicTable:'))

            setpref('matnwb', 'displaymode', 'groups')
            C = evalc('disp(module)');
            testCase.verifyTrue(contains(C, 'nwbdatainterface elements:'))
            testCase.verifyTrue(contains(C, 'dynamictable elements:'))
        end

        function testObjectWithAliasedNames(testCase)
            % Create a ProcessingModule
            module = types.core.ProcessingModule();
            
            % Add items with similar names that will evaluate to the same
            % valid name
            module.add('Time_Series', types.core.TimeSeries());
            % todo: Set needs to support names that will have the same alias
            module.add('Time-Series', types.core.TimeSeries());

            C = evalc('disp(module)');

            % Verify that the displayed object will contain a warning
            % message informing about "alias" names
            expectedMessage = 'Warning: The following named elements of "ProcessingModule"'; % ...
            testCase.verifyTrue( contains(C, expectedMessage)) 
            % Would use startsWith instead of contains, but C contains some 
            % hidden "display" characters in the beginning
        end

        function testListAliasNamesFromFile(testCase)

            nwbFile = tests.factory.NWBFile();
            
            ophysModule = types.core.ProcessingModule(...
                'description', 'optical physiology data');

            nwbFile.processing.add('ophys', ophysModule)

            fluorescence = tests.factory.Fluorescence(...
                tests.factory.RoiResponseSeries, ...
                "Name", "Roi-Response-Series");

            ophysModule.add('Raw-Fluorescence', fluorescence)

            result = nwbFile.listRemappedNames();
            
            testCase.verifySize(result, [2,4])
            testCase.verifyClass(result, 'table')

            testCase.verifyEqual(result.ActualName, ...
                ["Raw-Fluorescence"; "Roi-Response-Series"])
        end
    end
end
