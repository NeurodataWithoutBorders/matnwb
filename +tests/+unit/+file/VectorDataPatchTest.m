classdef VectorDataPatchTest < tests.abstract.NwbTestCase

    methods (Test)
        function testVectorDataUnitIsNotInjected(testCase)
            vectorDataClass = ?types.hdmf_common.VectorData;
            vectorDataPropertyNames = {vectorDataClass.PropertyList.Name};

            testCase.verifyFalse(ismember('unit', vectorDataPropertyNames))
            testCase.verifyTrue(ismember('sampling_rate', vectorDataPropertyNames))
            testCase.verifyTrue(ismember('resolution', vectorDataPropertyNames))

            unitsClass = ?types.core.Units;
            unitsPropertyNames = {unitsClass.PropertyList.Name};

            testCase.verifyTrue(ismember('waveform_mean_unit', unitsPropertyNames))
            testCase.verifyTrue(ismember('waveform_sd_unit', unitsPropertyNames))
            testCase.verifyTrue(ismember('waveforms_unit', unitsPropertyNames))
        end
    end
end
