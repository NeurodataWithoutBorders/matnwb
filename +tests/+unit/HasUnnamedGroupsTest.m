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
            % Test `add` and `remove` methods of HasUnnamedGroups mixin
            
            % Create a ProcessingModule and use the add method
            module = types.core.ProcessingModule();
            module.add('TimeSeries', types.core.TimeSeries());
            
            % Verify that the dynamic property was created
            testCase.verifyTrue(isprop(module, 'TimeSeries'), ...
                'Dynamic property was not created');
            
            % Verify that the dynamic property returns the correct type
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
        
        function testInitializeWithConstructorArgs(testCase)
            module = types.core.ProcessingModule(...
                'description', 'test module', ...
                'TimeSeries', tests.factory.TimeSeriesWithTimestamps, ...
                'DynamicTable', types.hdmf_common.DynamicTable() );

            testCase.verifyTrue( isprop(module, 'TimeSeries') )
            testCase.verifyTrue( isprop(module, 'DynamicTable') )
        end

        % % % function testGet(testCase)
        % % %     % Create a ProcessingModule
        % % %     module = types.core.ProcessingModule('description', 'test module');
        % % %     module.nwbdatainterface.set('TimeSeries', types.core.TimeSeries());
        % % %     module.dynamictable.set('DynamicTable', types.hdmf_common.DynamicTable());
        % % % 
        % % %     timeSeries = module.get('TimeSeries');
        % % %     testCase.verifyClass(timeSeries, 'types.core.TimeSeries')
        % % % 
        % % %     dynamicTable = module.get('DynamicTable');
        % % %     testCase.verifyClass(dynamicTable, 'types.hdmf_common.DynamicTable')
        % % % 
        % % %     testCase.verifyError(...
        % % %         @() module.get('NonExistingName'), ...
        % % %         'NWB:HasUnnamedGroups:ObjectDoesNotExist')
        % % % end

        function testLegacySyntax(testCase)
            % Create a ProcessingModule
            module = types.core.ProcessingModule();
            
            % Add a new type using the Set interface
            module.nwbdatainterface.set('TimeSeries', types.core.TimeSeries());
            
            % Verify that the dynamic property was created
            testCase.verifyTrue(isprop(module, 'TimeSeries'), ...
                'Dynamic property was not created');

            timeSeries = module.nwbdatainterface.get('TimeSeries');
            
            % Verify that the dynamic property returns the correct value
            testCase.verifyClass(timeSeries, ...
                'types.core.TimeSeries', ...
                'Dynamic property returned incorrect value');
            
            % Remove the item and verify it's gone
            module.nwbdatainterface.remove('TimeSeries');
            testCase.verifyFalse(isprop(module, 'TimeSeries'), ...
                'Dynamic property was not removed');
        end

        function testRemoveUsingPropertyName(testCase)
            module = types.core.ProcessingModule('description', 'test module');
            module.add('time series', types.core.TimeSeries())

            operationToVerify = @() module.remove('timeSeries');

            testCase.verifyWarning(operationToVerify, ...
                'NWB:HasUnnamedGroups:UseOriginalName' )
        end

        function testWithReservedName(testCase)
            module = types.core.ProcessingModule('description', 'test module');
            
            module.add('nwbdatainterface', types.core.NWBDataInterface());
            
            testCase.verifyTrue(isprop(module, 'nwbdatainterface'))
            testCase.verifyClass(module.nwbdatainterface, 'types.untyped.Set');

            testCase.verifyTrue(isprop(module, 'nwbdatainterface_'))
            testCase.verifyClass(module.nwbdatainterface_, 'types.core.NWBDataInterface');
        end
        
        function testWithReservedNameAddedToContainedSet(testCase)
            module = types.core.ProcessingModule('description', 'test module');
            
            module.nwbdatainterface.set('nwbdatainterface', types.core.NWBDataInterface());
            
            testCase.verifyTrue(isprop(module, 'nwbdatainterface'))
            testCase.verifyClass(module.nwbdatainterface, 'types.untyped.Set');

            testCase.verifyTrue(isprop(module, 'nwbdatainterface_'))
            testCase.verifyClass(module.nwbdatainterface_, 'types.core.NWBDataInterface');
        end

        function testWithInvalidMatlabName(testCase)
            % Add object with name which is not a valid matlab identifier
            module = types.core.ProcessingModule();
            module.add('Time-Series', types.core.TimeSeries())

            % Verify that the dynamic property was created and is accessible
            % with a valid MATLAB name
            testCase.verifyTrue(isprop(module, 'Time_Series'), ...
                'Dynamic property was not created');

            testCase.verifyClass(module.Time_Series, ...
                'types.core.TimeSeries', ...
                'Dynamic property returned incorrect type');
        end

        function testWithSimilarNames(testCase)
            % Test handling of similar names that result in the same valid name

            % Create module and add items with similar names to it:
            module = types.core.ProcessingModule();
            module.add('Time_Series', types.core.TimeSeries())
            module.add('Time-Series', types.core.TimeSeries())

            % Verify that the dynamic property was created
            testCase.verifyTrue(isprop(module, 'Time_Series'), ...
                'Dynamic property was not created');

            % Verify that similarly named property was created
            testCase.verifyTrue(isprop(module, 'Time_Series_1'), ...
                'Dynamic property was not created');
        end
        
        function testAddWithExistingName(testCase)
            module = types.core.ProcessingModule('description', 'test module');
            module.add('TimeSeries', types.core.TimeSeries())
    
            % Adding a new object with the same name should fail
            operationToVerify = @()...
                module.add('TimeSeries', types.core.TimeSeries());

            testCase.verifyError(operationToVerify, ...
                'NWB:HasUnnamedGroups:KeyExists')
        end

        function testAddWithExistingNameToContainedSet(testCase)
            module =  types.core.ProcessingModule(...
                'description', 'test module', ...
                'TimeSeries', types.core.TimeSeries());

            % Set a data object using the same name to the dynamic table group 
            % using legacy syntax. This should be intercepted by the 
            % ProcessingModule via the mixin.
            operationToVerify = @()...
                module.dynamictable.set( ...
                    'TimeSeries', types.hdmf_common.DynamicTable());
            
            testCase.verifyError(operationToVerify, ...
                'NWB:HasUnnamedGroups:DuplicateEntry')
        end
        
        function testOverrideExistingEntry(testCase)
            module = types.core.ProcessingModule(...
                'description', 'test module', ...
                'Test', types.core.TimeSeries());
            
            testCase.verifyTrue(isprop(module, 'Test'), ...
                'Dynamic property Test was not created');

            % Override it with a different type
            module.Test = types.core.Fluorescence();

            % Verify the property has the new type
            testCase.verifyClass(module.Test, 'types.core.Fluorescence', ...
                'Dynamic property Test did not return the overridden value');
        end

        function testAddInvalidType(testCase)
            module = types.core.ProcessingModule();
            
            operationToVerify = @()...
                module.add('Device', types.core.Device());
            
            testCase.verifyError(operationToVerify, ...
                'NWB:HasUnnamedGroups:AddInvalidType')
        end

        function testObjectDisplay(testCase)
            % Create a ProcessingModule with objects in each subgroup
            module = types.core.ProcessingModule();
            module.add('TimeSeries', types.core.TimeSeries());
            module.add('DynamicTable', types.hdmf_common.DynamicTable());

            % Verify both display modes
            origPrefValue = getpref('matnwb', 'displaymode', 'flat');
            testCase.addTeardown(@() setpref('matnwb', 'displaymode', origPrefValue))

            setpref('matnwb', 'displaymode', 'flat')
            C = evalc('disp(module)');
            testCase.verifyFalse(contains(C, 'nwbdatainterface group'))
            testCase.verifyFalse(contains(C, 'dynamictable group'))
            testCase.verifyTrue(contains(C, 'TimeSeries:'))
            testCase.verifyTrue(contains(C, 'DynamicTable:'))

            setpref('matnwb', 'displaymode', 'groups')
            C = evalc('disp(module)');
            testCase.verifyTrue(contains(C, 'nwbdatainterface group'))
            testCase.verifyTrue(contains(C, 'dynamictable group'))
            testCase.verifyTrue(contains(C, 'TimeSeries:'))
        end

        function testDisplayObjectWithAliasNamesShowsWarning(testCase)
            % Create a ProcessingModule and add entries with names that
            % will evaluate to the same valid identifier
            module = types.core.ProcessingModule('description', 'test module');
            module.add('Time_Series', types.core.TimeSeries());
            module.add('Time-Series', types.core.TimeSeries());

            % Display the object to trigger alias warning. Use evalc to hide 
            % output from test logs
            C = evalc('disp(module)'); %#ok<NASGU>
        
            % Verify that warning was triggered
            expectedWarningId = 'NWB:DynamicPropertyAliasWarning';
            [~, lastWarnId] = lastwarn();
            testCase.verifyTrue( strcmp(lastWarnId, expectedWarningId))
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

            testCase.verifyEqual(result.OriginalName, ...
                ["Raw-Fluorescence"; "Roi-Response-Series"])
        end
    end
end
