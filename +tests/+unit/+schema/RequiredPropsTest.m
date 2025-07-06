classdef RequiredPropsTest < tests.unit.abstract.SchemaTest

    properties (Constant)
        SchemaFolder = "requiredPropsSchema"
        SchemaNamespaceFileName = "rps.namespace.yaml"
    end
    properties
        nwbFileObj
        testGroup
        nwbFileName
    end
    
    methods (TestMethodSetup)
        function setupNwbFile(testCase)
            % Create a valid NWB file for each test
            testCase.nwbFileObj = NwbFile(...
                'identifier', 'REQPROPS', ...
                'session_description', 'required properties testing', ...
                'session_start_time', datetime());

            % Add a test group to the file's acquisition group
            testCase.testGroup = types.rps.TestGroup();
            testCase.nwbFileObj.acquisition.set('Test', testCase.testGroup);

            % Create a filename for each test
            try
                testCase.nwbFileName = matlab.lang.internal.uuid() + ".nwb";
            catch
                randUuid = string(java.util.UUID.randomUUID().toString());
                testCase.nwbFileName = randUuid + ".nwb";
            end
        end
    end

    methods (Test)
        function testDatasetWithRequiredAttributes(testCase)
            % Create a dataset with missing required attributes
            dataIncomplete = types.rps.DataWithRequiredAttribute(...
                'data', 1.0);
            
            % Add dataset to test group and include in NWB File
            testCase.testGroup.testdata.set('DataWithMissingRequiredAttribute', dataIncomplete);
            
            % Test that exporting fails due to missing required attribute
            testCase.verifyError( ...
                @() nwbExport(testCase.nwbFileObj, testCase.nwbFileName), ...
                'NWB:RequiredPropertyMissing');
            
            % Create a dataset with non-missing required attributes
            dataComplete = types.rps.DataWithRequiredAttribute(...
                'data', 1.0, ...
                'required_attr', 'value');
            
            % Replace dataset in TestGroup
            testCase.testGroup.testdata.remove('DataWithMissingRequiredAttribute');
            testCase.testGroup.testdata.set('DataWithRequiredAttribute', dataComplete);
            
            % Test that exporting now succeeds
            nwbExport(testCase.nwbFileObj, testCase.nwbFileName);
        end
        
        function testInheritanceOverrideToRequired(testCase)
            % Test base dataset with optional attributes
            baseDataset = types.rps.BaseDataWithOptionalAttributes('data', 1.0);
            testCase.testGroup.testdata.set('BaseDataset', baseDataset);
            
            % Export should succeed since attributes are optional
            nwbExport(testCase.nwbFileObj, testCase.nwbFileName);
            delete(testCase.nwbFileName)
            
            % Test extended dataset that makes attributes required
            extDatasetIncomplete = types.rps.ExtendedDataMakingOptionalAttributeRequired('data', 1.0);
            testCase.testGroup.testdata.set('ExtendedDatasetIncomplete', extDatasetIncomplete);
            
            % Export should fail due to missing required attributes
            testCase.verifyError( ...
                @() nwbExport(testCase.nwbFileObj, testCase.nwbFileName), ...
                'NWB:RequiredPropertyMissing');
            
            % Test with only one required attribute provided
            testCase.testGroup.testdata.remove('ExtendedDatasetIncomplete');
            extDatasetPartial = types.rps.ExtendedDataMakingOptionalAttributeRequired('data', 1.0, 'attr1', 'value');
            testCase.testGroup.testdata.set('ExtendedDatasetPartial', extDatasetPartial);
            
            % Export should still fail due to missing attr3
            testCase.verifyError(@() nwbExport(testCase.nwbFileObj, testCase.nwbFileName), ...
                'NWB:RequiredPropertyMissing');
            
            % Test with all required attributes provided
            testCase.testGroup.testdata.remove('ExtendedDatasetPartial');
            extDatasetComplete = types.rps.ExtendedDataMakingOptionalAttributeRequired('data', 1.0, 'attr1', 'value', 'attr3', 5);
            testCase.testGroup.testdata.set('ExtendedDatasetComplete', extDatasetComplete);
            
            % Export should succeed
            nwbExport(testCase.nwbFileObj, testCase.nwbFileName);
        end
        
        function testInheritanceOverrideToOptional(testCase)
            % Test base dataset with required attributes but missing them
            baseDatasetIncomplete = types.rps.BaseDataWithRequiredAttributes('data', 1.0);
            testCase.testGroup.testdata.set('BaseDatasetIncomplete', baseDatasetIncomplete);
            
            % Export should fail due to missing required attribute
            testCase.verifyError( ...
                @() nwbExport(testCase.nwbFileObj, testCase.nwbFileName), ...
                'NWB:RequiredPropertyMissing');
            
            % Test base dataset with all required attributes
            testCase.testGroup.testdata.remove('BaseDatasetIncomplete');
            baseDatasetComplete = types.rps.BaseDataWithRequiredAttributes('data', 1.0, 'req_attr', 'value');
            testCase.testGroup.testdata.set('BaseDatasetComplete', baseDatasetComplete);
            
            % Export should succeed
            nwbExport(testCase.nwbFileObj, testCase.nwbFileName);
            delete(testCase.nwbFileName)
            
            % Test extended dataset that makes required attributes optional
            extDataset = types.rps.ExtendedDataMakingRequiredAttributeOptional('data', 1.0);
            testCase.testGroup.testdata.set('ExtendedValidDataset', extDataset);
            
            % Export should succeed even without setting req_attr (now optional)
            nwbExport(testCase.nwbFileObj, testCase.nwbFileName);
        end
        
        function testGroupWithRequiredDatasets(testCase)
            % Test group with missing required datasets
            groupIncomplete = types.rps.GroupWithRequiredDatasets();
            testCase.testGroup.testgroup.set('GroupIncomplete', groupIncomplete);
            
            % Export should fail due to missing required dataset
            testCase.verifyError(...
                @() nwbExport(testCase.nwbFileObj, testCase.nwbFileName), ...
                'NWB:RequiredPropertyMissing');
            
            % Test group with all required datasets
            testCase.testGroup.testgroup.remove('GroupIncomplete');
            groupComplete = types.rps.GroupWithRequiredDatasets('required_dataset', 1.0);
            testCase.testGroup.testgroup.set('GroupComplete', groupComplete);
            
            % Export should succeed
            nwbExport(testCase.nwbFileObj, testCase.nwbFileName);
        end
        
        function testGroupWithRequiredLinks(testCase)
            % Test group with missing required links
            groupIncomplete = types.rps.GroupWithRequiredLinks();
            testCase.testGroup.testgroup.set('GroupIncomplete', groupIncomplete);
            
            % Export should fail due to missing required link
            testCase.verifyError(...
                @() nwbExport(testCase.nwbFileObj, testCase.nwbFileName), ...
                'NWB:RequiredPropertyMissing');
            
            testCase.testGroup.testgroup.remove('GroupIncomplete');

            % Create a data interface to use as a link target
            dataInterface = types.core.NWBDataInterface();
            testCase.nwbFileObj.acquisition.set('LinkTarget', dataInterface);

            % Test group with all required links
            groupComplete = types.rps.GroupWithRequiredLinks('required_link', dataInterface);
            testCase.testGroup.testgroup.set('GroupComplete', groupComplete);
            
            % Export should succeed
            nwbExport(testCase.nwbFileObj, testCase.nwbFileName);
        end
        
        function testGroupInheritanceOverride(testCase)
            % Test base group with optional components
            baseGroup = types.rps.BaseGroup();
            testCase.testGroup.testgroup.set('baseGroup', baseGroup);
            
            % Export should succeed since components are optional
            nwbExport(testCase.nwbFileObj, testCase.nwbFileName);
            
            % Test extended group with missing required components
            extGroupMissing = types.rps.ExtendedGroup();
            testCase.testGroup.testgroup.set('extGroupMissing', extGroupMissing);
            
            % Export should fail due to missing required components
            testCase.verifyError(...
                @() nwbExport(testCase.nwbFileObj, testCase.nwbFileName), ...
                'NWB:RequiredPropertyMissing');
                       
            % Test extended group with all required components
            testCase.testGroup.testgroup.remove('extGroupMissing');

            % Create a subgroup to use
            subgroup = types.core.NWBDataInterface();

            extGroupComplete = types.rps.ExtendedGroup('dataset1', 1.0, 'attr1', 'value');
            extGroupComplete.subgroup1.set('SubGroup', subgroup);
            testCase.testGroup.testgroup.set('extGroupComplete', extGroupComplete);
            
            % Export should succeed
            nwbExport(testCase.nwbFileObj, testCase.nwbFileName);
        end
        
        function testMixedRequiredGroup(testCase)
            % Create objects to use as subgroups and links
            subgroup = types.core.NWBContainer();
            dataInterface = types.core.NWBDataInterface();
            
            % Test group with missing required components
            groupIncomplete = types.rps.MixedRequiredGroup();
            testCase.testGroup.testgroup.set('GroupIncomplete', groupIncomplete);
            
            % Export should fail due to missing required components
            testCase.verifyError(...
                @() nwbExport(testCase.nwbFileObj, testCase.nwbFileName), ...
                'NWB:RequiredPropertyMissing');
            
            % Test group with only some required components
            testCase.testGroup.testgroup.remove('GroupIncomplete');
            groupPartial = types.rps.MixedRequiredGroup('required_dataset', 1.0);
            testCase.testGroup.testgroup.set('GroupPartial', groupPartial);
            
            % Export should still fail
            testCase.verifyError(@() nwbExport(testCase.nwbFileObj, testCase.nwbFileName), ...
                'NWB:RequiredPropertyMissing');
            
            % Add data interface as a link target
            testCase.nwbFileObj.acquisition.set('LinkTarget', dataInterface);

            % Test group with all required components
            testCase.testGroup.testgroup.remove('GroupPartial');
            groupComplete = types.rps.MixedRequiredGroup(...
                'required_dataset', 1.0, ...
                'required_group', types.untyped.Set('subgroup', subgroup), ...
                'required_attr', 'value', ...
                'required_link', dataInterface);
            testCase.testGroup.testgroup.set('GroupComplete', groupComplete);
            
            % Export should succeed
            nwbExport(testCase.nwbFileObj, testCase.nwbFileName);
            
            % Add optional components and verify export still works
            groupComplete.optional_dataset = 'optional value';
            groupComplete.optional_group.set('OptionalSubgroup', subgroup);
            groupComplete.optional_attr = 2.5;
            groupComplete.optional_link = dataInterface;
            
            nwbExport(testCase.nwbFileObj, testCase.nwbFileName);
        end
        
        function testCompleteExportAndRead(testCase)
            % Test exporting an NWB file with objects that have all required properties
            % and reading it back to verify the properties are preserved
            
            % Create objects with all required properties
            dataset = types.rps.DataWithRequiredAttribute('data', 1.0, 'required_attr', 'value');
            baseDataset = types.rps.BaseDataWithRequiredAttributes('data', 1.0, 'req_attr', 'value');
            
            dataInterface = types.core.NWBDataInterface();
            subgroup = types.core.NWBContainer();
            
            % Add data interface as a link target
            testCase.nwbFileObj.acquisition.set('LinkTarget', dataInterface);

            mixedGroup = types.rps.MixedRequiredGroup(...
                'required_dataset', 1.0, ...
                'required_group', types.untyped.Set('SubgroupOfRequiredGroup', subgroup), ...
                'required_attr', 'value', ...
                'required_link', dataInterface);
            
            % Add objects to the NWB file
            testCase.testGroup.testdata.set('Dataset', dataset);
            testCase.testGroup.testdata.set('BaseDataset', baseDataset);
            testCase.testGroup.testgroup.set('MixedGroup', mixedGroup);
            
            % Export the file
            nwbExport(testCase.nwbFileObj, testCase.nwbFileName);
            
            % Read the file back and verify the required properties
            nwbObj = nwbRead(testCase.nwbFileName, 'ignorecache');
            
            % Verify dataset properties
            readDataset = nwbObj.acquisition.get('Test').testdata.get('Dataset');
            testCase.verifyEqual(readDataset.required_attr, 'value');
            
            % Verify base dataset properties
            readBaseDataset = nwbObj.acquisition.get('Test').testdata.get('BaseDataset');
            testCase.verifyEqual(readBaseDataset.req_attr, 'value');
            
            % Verify mixed group properties
            readMixedGroup = nwbObj.acquisition.get('Test').testgroup.get('MixedGroup');
            testCase.verifyEqual(readMixedGroup.required_dataset, 1.0);
            testCase.verifyEqual(readMixedGroup.required_attr, 'value')
        end
    end
end
