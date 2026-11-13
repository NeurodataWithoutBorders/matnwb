classdef ExtensionRequirementTest < matlab.unittest.TestCase
% ExtensionRequirementTest - Tests for reading the requirements of extension packages.
%
%   The requirement texts are taken from the PyPI metadata of published
%   NWB extensions.

    methods (Test)
        function testExactPin(testCase)
            requirement = matnwb.extension.internal.parseRequirement("ndx-ophys-devices==0.2.0");
            testCase.verifyEqual(requirement.Name, "ndx-ophys-devices")
            testCase.verifyEqual(requirement.Specifiers, "==0.2.0")
            testCase.verifyFalse(requirement.IsOptional)
        end

        function testParenthesizedSpecifier(testCase)
            requirement = matnwb.extension.internal.parseRequirement("ndx-events (>=0.4.0)");
            testCase.verifyEqual(requirement.Name, "ndx-events")
            testCase.verifyEqual(requirement.Specifiers, ">=0.4.0")
        end

        function testSeveralSpecifiersAndExtras(testCase)
            requirement = matnwb.extension.internal.parseRequirement("NDX_Some.Ext[dev] >=0.2, <0.4");
            testCase.verifyEqual(requirement.Name, "ndx-some-ext")
            testCase.verifyEqual(requirement.Specifiers, [">=0.2", "<0.4"])
        end

        function testRequirementOfOptionalFeature(testCase)
            requirement = matnwb.extension.internal.parseRequirement( ...
                "ndx-optogenetics==0.2.0; extra == ""min-reqs""");
            testCase.verifyTrue(requirement.IsOptional)
        end

        function testRequirementWithoutVersion(testCase)
            requirement = matnwb.extension.internal.parseRequirement("pynwb");
            testCase.verifyEqual(requirement.Name, "pynwb")
            testCase.verifyEmpty(requirement.Specifiers)
        end

        function testVersionComparisons(testCase)
            import matnwb.extension.internal.isVersionSatisfied
            testCase.verifyTrue(isVersionSatisfied("0.2.0", "==0.2.0"))
            testCase.verifyTrue(isVersionSatisfied("0.2", "==0.2.0"))
            testCase.verifyFalse(isVersionSatisfied("0.3.1", "==0.2.0"))
            testCase.verifyTrue(isVersionSatisfied("0.3.10", ">=0.3.9"))
            testCase.verifyFalse(isVersionSatisfied("0.3.1", ">0.3.1"))
            testCase.verifyTrue(isVersionSatisfied("0.3.0", [">=0.2", "<0.4"]))
            testCase.verifyFalse(isVersionSatisfied("0.4.0", [">=0.2", "<0.4"]))
            testCase.verifyTrue(isVersionSatisfied("0.4.0", strings(1, 0)))
        end

        function testWildcardAndCompatibleRelease(testCase)
            import matnwb.extension.internal.isVersionSatisfied
            testCase.verifyTrue(isVersionSatisfied("1.4.7", "==1.4.*"))
            testCase.verifyFalse(isVersionSatisfied("1.5.0", "==1.4.*"))
            testCase.verifyTrue(isVersionSatisfied("1.4.5", "~=1.4.2"))
            testCase.verifyFalse(isVersionSatisfied("1.5.0", "~=1.4.2"))
            testCase.verifyFalse(isVersionSatisfied("1.4.1", "~=1.4.2"))
        end

        function testPreReleaseMeetsOnlyExactPin(testCase)
            import matnwb.extension.internal.isVersionSatisfied
            testCase.verifyFalse(isVersionSatisfied("0.5.0rc1", ">=0.4.0"))
            testCase.verifyTrue(isVersionSatisfied("0.5.0rc1", "==0.5.0rc1"))
        end

        function testInvalidSpecifierThrows(testCase)
            testCase.verifyError( ...
                @() matnwb.extension.internal.isVersionSatisfied("0.1.0", "=>0.1"), ...
                "NWB:InstallExtension:InvalidVersionSpecifier")
        end
    end
end
