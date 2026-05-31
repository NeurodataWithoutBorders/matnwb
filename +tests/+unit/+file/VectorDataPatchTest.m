classdef VectorDataPatchTest < tests.abstract.NwbTestCase

    methods (Test)
        function testVectorDataUnitIsNotInjected(testCase)
            vectorDataClass = ?types.hdmf_common.VectorData;
            vectorDataPropertyNames = {vectorDataClass.PropertyList.Name};

            testCase.verifyFalse(ismember('unit', vectorDataPropertyNames))
            testCase.verifyFalse(ismember('sampling_rate', vectorDataPropertyNames))
            testCase.verifyFalse(ismember('resolution', vectorDataPropertyNames))

            unitsClass = ?types.core.Units;
            unitsPropertyNames = {unitsClass.PropertyList.Name};

            testCase.verifyTrue(ismember('waveform_mean_unit', unitsPropertyNames))
            testCase.verifyTrue(ismember('waveform_sd_unit', unitsPropertyNames))
            testCase.verifyTrue(ismember('waveforms_unit', unitsPropertyNames))
        end

        function testUnitsDoesNotSyncPromotedUnitAttributesFromVectorData(testCase)
            unitsFile = fullfile( ...
                testCase.getTypesOutputFolder(), ...
                '+types', '+core', 'Units.m');
            unitsContents = string(fileread(unitsFile));

            testCase.verifyFalse(contains(unitsContents, 'obj.waveform_mean.unit'))
            testCase.verifyFalse(contains(unitsContents, 'obj.waveform_sd.unit'))
            testCase.verifyFalse(contains(unitsContents, 'obj.waveforms.unit'))
        end
    end
end
