classdef LinkSpecTest < tests.unit.abstract.SchemaTest
% Test case for the LinkContainer (test) extension with different link specifications. 
%
%  Verifies correct handling of:
%  - a named link with target_type set to TypeA
%  - an unnamed scalar link with target_type set to TypeB
%  - an unnamed multi-link (quantity: '*') with target_type set to TypeC
%
%  Each of the items above are tested both with the exact target type as
%  well as a sub-type of the target_type.
%
%  Verifies that the different link types listed above (with exact type and 
%  subtype for target_type) can be exported and imported with nwbExport and 
%  nwbRead. 

    properties (Constant)
        SchemaFolder = "linkSchema"
        SchemaNamespaceFileName = "link.namespace.yaml"
    end

    properties (TestParameter)
        % Use test parameters to test that adding links works for both types
        % and subtypes for a given target_type
        TypeA = {'types.link.TypeA', 'types.link.SubTypeA'}
        TypeB = {'types.link.TypeB', 'types.link.SubTypeB'}
        TypeC = {'types.link.TypeC', 'types.link.SubTypeC'}
    end

    methods (Test)
        function testCreateTypeWithNamedLink(testCase, TypeA)
            linkContainer = types.link.LinkContainer(...
                'named_link', feval(TypeA));
            
            testCase.verifyNamedLink(linkContainer, TypeA)
        end
               
        function testCreateTypeWithUnnamedScalarLink(testCase, TypeB)
            linkContainer = types.link.LinkContainer(...
                'linked_type_b', feval(TypeB));

            testCase.verifyUnnamedScalarLink(linkContainer, TypeB)
        end

        function testCreateTypeWithUnnamedNonScalarLink(testCase, TypeC)
            linkContainer = types.link.LinkContainer(...
                'linked_type_c1', feval(TypeC), ...
                'linked_type_c2', feval(TypeC));
            
            testCase.verifyUnnamedNonScalarLink(linkContainer, TypeC)
        end

        function testCreateTypeWithUnnamedLinkOfWrongType(testCase)
            % Trying to add a link with wrong type to a constrained set will 
            % show a warning and the type will not be picked up by any of
            % the LinkContainer's constrained sets
            linkContainer = testCase.verifyWarning(...
                @() types.link.LinkContainer('linked_type_b', types.link.TypeA()), ...
                'NWB:CheckUnset:InvalidProperties');

            % Verify that the type was not added to any of the constrained
            % sets that accept linked types of either TypeB or TypeC
            testCase.verifyFalse(linkContainer.typeb.isKey('linked_type_b'))
            testCase.verifyFalse(linkContainer.typec.isKey('linked_type_b'))
        end
    end

    methods (Test, ParameterCombination="sequential")
        function testLinkContainerRoundTrip(testCase, TypeA, TypeB, TypeC)
            % Create NWB file with objects that will be linked
            nwb = tests.factory.NWBFile();
            nwb.acquisition.set('TypeA', feval(TypeA));
            nwb.acquisition.set('TypeB', feval(TypeB));
            nwb.acquisition.set('TypeC1', feval(TypeC));
            nwb.acquisition.set('TypeC2', feval(TypeC));

            % Create link container with linked types
            linkContainer = types.link.LinkContainer(...
                'named_link', nwb.acquisition.get('TypeA'), ...
                'linked_type_b', nwb.acquisition.get('TypeB'), ...
                'linked_type_c1', nwb.acquisition.get('TypeC1'), ...
                'linked_type_c2', nwb.acquisition.get('TypeC2') ...
                );
            nwb.acquisition.set('LinkContainer', linkContainer);

            % Export and re-import nwb file
            fileName = 'link_roundtrip_test.nwb';
            nwbExport(nwb, fileName, 'overwrite')

            nwbIn = nwbRead(fileName, 'ignorecache');
            linkContainerIn = nwbIn.acquisition.get('LinkContainer');

            testCase.verifyNamedLink(linkContainerIn, TypeA)
            testCase.verifyUnnamedScalarLink(linkContainerIn, TypeB)
            testCase.verifyUnnamedNonScalarLink(linkContainerIn, TypeC)
        end
    end

    methods (Access = private) % Verification helpers
        function verifyNamedLink(testCase, linkContainer, targetType)
            testCase.verifyClass(linkContainer.named_link, 'types.untyped.SoftLink')
            testCase.verifyClass(linkContainer.named_link.target, targetType)
        end

        function verifyUnnamedScalarLink(testCase, linkContainer, targetType)
            testCase.verifyClass(linkContainer.typeb, 'types.untyped.Set')
            testCase.verifyTrue(linkContainer.typeb.isKey('linked_type_b'))
            testCase.verifyClass(linkContainer.typeb.get('linked_type_b'), 'types.untyped.SoftLink')
            testCase.verifyClass(linkContainer.typeb.get('linked_type_b').target, targetType)
        end

        function verifyUnnamedNonScalarLink(testCase, linkContainer, targetType)
            testCase.verifyClass(linkContainer.typec, 'types.untyped.Set')
            testCase.verifyTrue(linkContainer.typec.isKey('linked_type_c1') )
            testCase.verifyTrue(linkContainer.typec.isKey('linked_type_c2') )
            testCase.verifyClass(linkContainer.typec.get('linked_type_c1').target, targetType)
            testCase.verifyClass(linkContainer.typec.get('linked_type_c2').target, targetType)
        end
    end
end
