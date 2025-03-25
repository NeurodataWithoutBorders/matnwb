classdef RequiredPropsTest < tests.unit.abstract.SchemaTest

    properties (Constant)
        SchemaFolder = "requiredPropsSchema"
        SchemaNamespaceFileName = "rps.namespace.yaml"
    end
    properties
        nwbFile
    end
    
    methods (TestMethodSetup)
        function setupNwbFile(testCase)
            % Create a valid NWB file for each test
            testCase.nwbFile = NwbFile(...
                'identifier', 'REQPROPS', ...
                'session_description', 'required properties testing', ...
                'session_start_time', datetime());
        end
    end

    methods (Test)
        function testDatasetWithRequiredAttributes(testCase)
            % Create a dataset with missing required attributes
            datasetMissing = types.rps.DatasetWithRequiredAttr('data', 1.0);
            
            % Add to NWB file
            testCase.nwbFile.scratch.set('datasetMissing', datasetMissing);
            
            % Test that exporting fails due to missing required attribute
            filename = matlab.lang.internal.uuid() + ".nwb";
            testCase.verifyError(@() nwbExport(testCase.nwbFile, filename), ...
                'NWB:RequiredPropertyMissing');
            
            % Create a dataset with all required attributes
            datasetComplete = types.rps.DatasetWithRequiredAttr('data', 1.0, 'required_attr', 'value');
            
            % Replace in NWB file
            testCase.nwbFile.scratch.remove('datasetMissing');
            testCase.nwbFile.scratch.set('datasetComplete', datasetComplete);
            
            % Test that exporting succeeds
            nwbExport(testCase.nwbFile, filename);
        end
        
        function testInheritanceOverrideToRequired(testCase)
            % Test base dataset with optional attributes
            baseDataset = types.rps.BaseDataset('data', 1.0);
            testCase.nwbFile.scratch.set('baseDataset', baseDataset);
            
            % Export should succeed since attributes are optional
            filename = matlab.lang.internal.uuid() + ".nwb";
            nwbExport(testCase.nwbFile, filename);
            
            % Test extended dataset that makes attributes required
            extDatasetMissing = types.rps.ExtendedDataset('data', 1.0);
            testCase.nwbFile.scratch.set('extDatasetMissing', extDatasetMissing);
            
            % Export should fail due to missing required attributes
            testCase.verifyError(@() nwbExport(testCase.nwbFile, filename), ...
                'NWB:RequiredPropertyMissing');
            
            % Test with only one required attribute provided
            testCase.nwbFile.scratch.remove('extDatasetMissing');
            extDatasetPartial = types.rps.ExtendedDataset('data', 1.0, 'attr1', 'value');
            testCase.nwbFile.scratch.set('extDatasetPartial', extDatasetPartial);
            
            % Export should still fail due to missing attr3
            testCase.verifyError(@() nwbExport(testCase.nwbFile, filename), ...
                'NWB:RequiredPropertyMissing');
            
            % Test with all required attributes provided
            testCase.nwbFile.scratch.remove('extDatasetPartial');
            extDatasetComplete = types.rps.ExtendedDataset('data', 1.0, 'attr1', 'value', 'attr3', 5);
            testCase.nwbFile.scratch.set('extDatasetComplete', extDatasetComplete);
            
            % Export should succeed
            nwbExport(testCase.nwbFile, filename);
        end
        
        function testInheritanceOverrideToOptional(testCase)
            % Test base dataset with required attributes but missing them
            baseDatasetMissing = types.rps.BaseDatasetWithRequired('data', 1.0);
            testCase.nwbFile.scratch.set('baseDatasetMissing', baseDatasetMissing);
            
            % Export should fail due to missing required attribute
            filename = matlab.lang.internal.uuid() + ".nwb";
            testCase.verifyError(@() nwbExport(testCase.nwbFile, filename), ...
                'NWB:RequiredPropertyMissing');
            
            % Test base dataset with all required attributes
            testCase.nwbFile.scratch.remove('baseDatasetMissing');
            baseDatasetComplete = types.rps.BaseDatasetWithRequired('data', 1.0, 'req_attr', 'value');
            testCase.nwbFile.scratch.set('baseDatasetComplete', baseDatasetComplete);
            
            % Export should succeed
            nwbExport(testCase.nwbFile, filename);
            
            % Test extended dataset that makes required attributes optional
            extDataset = types.rps.ExtendedDatasetWithOptional('data', 1.0);
            testCase.nwbFile.scratch.set('extDataset', extDataset);
            
            % Export should succeed even without setting req_attr (now optional)
            nwbExport(testCase.nwbFile, filename);
        end
        
        function testGroupWithRequiredDatasets(testCase)
            % Test group with missing required datasets
            groupMissing = types.rps.GroupWithRequiredDatasets();
            testCase.nwbFile.scratch.set('groupMissing', groupMissing);
            
            % Export should fail due to missing required dataset
            filename = matlab.lang.internal.uuid() + ".nwb";
            testCase.verifyError(@() nwbExport(testCase.nwbFile, filename), ...
                'NWB:RequiredPropertyMissing');
            
            % Test group with all required datasets
            testCase.nwbFile.scratch.remove('groupMissing');
            groupComplete = types.rps.GroupWithRequiredDatasets('required_dataset', 1.0);
            testCase.nwbFile.scratch.set('groupComplete', groupComplete);
            
            % Export should succeed
            nwbExport(testCase.nwbFile, filename);
        end
        
        function testGroupWithRequiredLinks(testCase)

            % Test group with missing required links
            groupMissing = types.rps.GroupWithRequiredLinks();
            testCase.nwbFile.scratch.set('groupMissing', groupMissing);
            
            % Export should fail due to missing required link
            filename = matlab.lang.internal.uuid() + ".nwb";
            testCase.verifyError(@() nwbExport(testCase.nwbFile, filename), ...
                'NWB:RequiredPropertyMissing');
            
            testCase.nwbFile.scratch.remove('groupMissing');

            % Create a data interface to use as a link target
            dataInterface = types.core.NWBDataInterface();
            testCase.nwbFile.acquisition.set('LinkTarget', dataInterface);

            % Test group with all required links
            groupComplete = types.rps.GroupWithRequiredLinks('required_link', dataInterface);
            testCase.nwbFile.scratch.set('groupComplete', groupComplete);
            
            % Export should succeed
            nwbExport(testCase.nwbFile, filename);
        end
        
        function testGroupInheritanceOverride(testCase)
            % Test base group with optional components
            baseGroup = types.rps.BaseGroup();
            testCase.nwbFile.scratch.set('baseGroup', baseGroup);
            
            % Export should succeed since components are optional
            filename = matlab.lang.internal.uuid() + ".nwb";
            nwbExport(testCase.nwbFile, filename);
            
            % Test extended group with missing required components
            extGroupMissing = types.rps.ExtendedGroup();
            testCase.nwbFile.scratch.set('extGroupMissing', extGroupMissing);
            
            % Export should fail due to missing required components
            testCase.verifyError(@() nwbExport(testCase.nwbFile, filename), ...
                'NWB:RequiredPropertyMissing');
                       
            % Test extended group with all required components
            testCase.nwbFile.scratch.remove('extGroupMissing');


            % Create a subgroup to use
            subgroup = types.core.NWBDataInterface();

            extGroupComplete = types.rps.ExtendedGroup('dataset1', 1.0, 'attr1', 'value');
            extGroupComplete.subgroup1.set('SubGroup', subgroup);
            testCase.nwbFile.scratch.set('extGroupComplete', extGroupComplete);
            
            % Export should succeed
            nwbExport(testCase.nwbFile, filename);
        end
        
        function testMixedRequiredGroup(testCase)
            % Create objects to use as subgroups and links
            subgroup = types.core.NWBContainer();
            dataInterface = types.core.NWBDataInterface();
            
            % Test group with missing required components
            groupMissing = types.rps.MixedRequiredGroup();
            testCase.nwbFile.scratch.set('groupMissing', groupMissing);
            
            % Export should fail due to missing required components
            filename = matlab.lang.internal.uuid() + ".nwb";
            testCase.verifyError(@() nwbExport(testCase.nwbFile, filename), ...
                'NWB:RequiredPropertyMissing');
            
            % Test group with only some required components
            testCase.nwbFile.scratch.remove('groupMissing');
            groupPartial = types.rps.MixedRequiredGroup('required_dataset', 1.0);
            testCase.nwbFile.scratch.set('groupPartial', groupPartial);
            
            % Export should still fail
            testCase.verifyError(@() nwbExport(testCase.nwbFile, filename), ...
                'NWB:RequiredPropertyMissing');
            
            % Add data interface as a link target
            testCase.nwbFile.acquisition.set('LinkTarget', dataInterface);

            % Test group with all required components
            testCase.nwbFile.scratch.remove('groupPartial');
            groupComplete = types.rps.MixedRequiredGroup(...
                'required_dataset', 1.0, ...
                'required_group', types.untyped.Set('subgroup', subgroup), ...
                'required_attr', 'value', ...
                'required_link', dataInterface);
            testCase.nwbFile.scratch.set('groupComplete', groupComplete);
            
            % Export should succeed
            nwbExport(testCase.nwbFile, filename);
            
            % Add optional components and verify export still works
            groupComplete.optional_dataset = 'optional value';
            groupComplete.optional_group.set('OptionalSubgroup', subgroup);
            groupComplete.optional_attr = 2.5;
            groupComplete.optional_link = dataInterface;
            
            nwbExport(testCase.nwbFile, filename);
        end
        
        function testCompleteExportAndRead(testCase)
            % Test exporting an NWB file with objects that have all required properties
            % and reading it back to verify the properties are preserved
            
            % Create objects with all required properties
            dataset = types.rps.DatasetWithRequiredAttr('data', 1.0, 'required_attr', 'value');
            baseDataset = types.rps.BaseDatasetWithRequired('data', 1.0, 'req_attr', 'value');
            
            dataInterface = types.core.NWBDataInterface();
            subgroup = types.core.NWBContainer();
            
            % Add data interface as a link target
            testCase.nwbFile.acquisition.set('LinkTarget', dataInterface);

            mixedGroup = types.rps.MixedRequiredGroup(...
                'required_dataset', 1.0, ...
                'required_group', types.untyped.Set('SubgroupOfRequiredGroup', subgroup), ...
                'required_attr', 'value', ...
                'required_link', dataInterface);
            
            % Add objects to the NWB file
            testCase.nwbFile.scratch.set('dataset', dataset);
            testCase.nwbFile.scratch.set('baseDataset', baseDataset);
            testCase.nwbFile.scratch.set('mixedGroup', mixedGroup);
            
            % Export the file
            filename = matlab.lang.internal.uuid() + ".nwb";
            nwbExport(testCase.nwbFile, filename);
            
            % Read the file back and verify the required properties
            nwbObj = nwbRead(filename, 'ignorecache');
            
            % Verify dataset properties
            readDataset = nwbObj.scratch.get('dataset');
            testCase.verifyEqual(readDataset.required_attr, 'value');
            
            % Verify base dataset properties
            readBaseDataset = nwbObj.scratch.get('baseDataset');
            testCase.verifyEqual(readBaseDataset.req_attr, 'value');
            
            % Verify mixed group properties
            readMixedGroup = nwbObj.scratch.get('mixedGroup');
            testCase.verifyEqual(readMixedGroup.required_dataset, 1.0);
            testCase.verifyEqual(readMixedGroup.required_attr, 'value')
        end
    end
end
