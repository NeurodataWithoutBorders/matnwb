classdef GetNeurodataTypeInfoTest < matlab.unittest.TestCase
% GetNeurodataTypeInfoTest - Unit tests for io.getNeurodataTypeInfo function.

    properties (TestParameter)
        HDMFCommonType = {'DynamicTable', 'VectorData', 'VectorIndex'}
    end

    methods (Test)
        function testEmptyInput(testCase)
            % Test that empty input returns empty typeInfo
            typeInfo = io.getNeurodataTypeInfo([]);
            
            testCase.verifyEqual(typeInfo.namespace, '');
            testCase.verifyEqual(typeInfo.name, '');
            testCase.verifyEqual(typeInfo.typename, '');
        end
        
        function testValidNeurodataType(testCase)
            % Test with valid neurodata type and namespace
            attributeInfo = struct(...
                'Name', {'neurodata_type', 'namespace'}, ...
                'Value', {'DynamicTable', 'hdmf-common'});
            
            typeInfo = io.getNeurodataTypeInfo(attributeInfo);
            
            testCase.verifyEqual(typeInfo.namespace, 'hdmf-common');
            testCase.verifyEqual(typeInfo.name, 'DynamicTable');
            testCase.verifyEqual(typeInfo.typename, 'types.hdmf_common.DynamicTable');
        end
        
        function testOnlyNeurodataType(testCase)
            % Test with only neurodata_type attribute (no namespace)
            attributeInfo = struct(...
                'Name', {'neurodata_type'}, ...
                'Value', {'DynamicTable'});
            
            typeInfo = io.getNeurodataTypeInfo(attributeInfo);
            
            testCase.verifyEqual(typeInfo.namespace, '');
            testCase.verifyEqual(typeInfo.name, 'DynamicTable');
            testCase.verifyEqual(typeInfo.typename, '');
        end
        
        function testOnlyNamespace(testCase)
            % Test with only namespace attribute (no neurodata_type)
            attributeInfo = struct(...
                'Name', {'namespace'}, ...
                'Value', {'hdmf-common'});
            
            typeInfo = io.getNeurodataTypeInfo(attributeInfo);
            
            testCase.verifyEqual(typeInfo.namespace, 'hdmf-common');
            testCase.verifyEqual(typeInfo.name, '');
            testCase.verifyEqual(typeInfo.typename, '');
        end
        
        function testHdmfExperimentalFallbackToHdmfCommon(testCase, HDMFCommonType)
            % Test fallback correction for VectorData with incorrect 
            % hdmf-experimental namespace (should be hdmf-common)
            attributeInfo = struct(...
                'Name', {'neurodata_type', 'namespace'}, ...
                'Value', {HDMFCommonType, 'hdmf-experimental'});
            
            typeInfo = io.getNeurodataTypeInfo(attributeInfo);
            
            % Should be corrected to hdmf-common
            testCase.verifyEqual(typeInfo.namespace, 'hdmf-common');
            testCase.verifyEqual(typeInfo.name, HDMFCommonType);
            testCase.verifyEqual(typeInfo.typename, sprintf('types.hdmf_common.%s', HDMFCommonType));
        end
        
        function testCellStringValueHandling(testCase)
            % Test that cell string values are handled correctly
            attributeInfo = struct(...
                'Name', {'neurodata_type', 'namespace'}, ...
                'Value', {{'DynamicTable'}, {'hdmf-common'}});
            
            typeInfo = io.getNeurodataTypeInfo(attributeInfo);
            
            testCase.verifyEqual(typeInfo.namespace, 'hdmf-common');
            testCase.verifyEqual(typeInfo.name, 'DynamicTable');
            testCase.verifyEqual(typeInfo.typename, 'types.hdmf_common.DynamicTable');
        end
        
        function testNoFallbackForValidHdmfExperimentalType(testCase)
            % Test that valid hdmf-experimental types are not incorrectly 
            % changed to hdmf-common
            %
            % Note: This test verifies that if a type genuinely belongs to
            % hdmf-experimental and exists there, it should not be changed.
            % EnumData is an example type that exists only in 
            % hdmf-experimental.
            
            % First, check if types.hdmf_experimental exists and has types
            if exist('types.hdmf_experimental.EnumData', 'class') == 8
                attributeInfo = struct(...
                    'Name', {'neurodata_type', 'namespace'}, ...
                    'Value', {'EnumData', 'hdmf-experimental'});
                
                typeInfo = io.getNeurodataTypeInfo(attributeInfo);
                
                % Should remain hdmf-experimental since the class exists there
                testCase.verifyEqual(typeInfo.namespace, 'hdmf-experimental');
                testCase.verifyEqual(typeInfo.typename, 'types.hdmf_experimental.EnumData');
            else
                % If hdmf-experimental types don't exist, skip this test
                testCase.assumeTrue(false, ...
                    'Skipping test: types.hdmf_experimental.EnumData class not found');
            end
        end
        
        function testNoFallbackForNonExistentType(testCase)
            % Test that non-existent types in hdmf-experimental that also 
            % don't exist in hdmf-common remain unchanged (the typename 
            % will still point to hdmf-experimental since no fallback exists)
            attributeInfo = struct(...
                'Name', {'neurodata_type', 'namespace'}, ...
                'Value', {'NonExistentType', 'hdmf-experimental'});
            
            typeInfo = io.getNeurodataTypeInfo(attributeInfo);
            
            % Should remain hdmf-experimental since there's no hdmf-common fallback
            testCase.verifyEqual(typeInfo.namespace, 'hdmf-experimental');
            testCase.verifyEqual(typeInfo.name, 'NonExistentType');
            testCase.verifyEqual(typeInfo.typename, 'types.hdmf_experimental.NonExistentType');
        end
        
        function testCoreNamespaceUnchanged(testCase)
            % Test that core namespace types are not affected by fallback logic
            attributeInfo = struct(...
                'Name', {'neurodata_type', 'namespace'}, ...
                'Value', {'NWBFile', 'core'});
            
            typeInfo = io.getNeurodataTypeInfo(attributeInfo);
            
            testCase.verifyEqual(typeInfo.namespace, 'core');
            testCase.verifyEqual(typeInfo.name, 'NWBFile');
            testCase.verifyEqual(typeInfo.typename, 'types.core.NWBFile');
        end
    end
end
