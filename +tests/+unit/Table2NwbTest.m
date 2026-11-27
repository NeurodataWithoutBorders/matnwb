classdef Table2NwbTest < tests.abstract.NwbTestCase
% Table2NwbTest - Tests for the column descriptions that util.table2nwb
% writes when it converts a MATLAB table to a DynamicTable.

    methods (Test)
        function testColumnWithoutDescriptionGetsPlaceholder(testCase)
            % NWB Inspector reports "no description" as a placeholder, so an
            % undescribed column is flagged when the file is inspected.
            matlabTable = table([1; 2], 'VariableNames', {'reward_size'});

            dynamicTable = util.table2nwb(matlabTable);

            testCase.verifyEqual( ...
                dynamicTable.vectordata.get('reward_size').description, 'no description')
        end

        function testColumnDescriptionIsTakenFromVariableDescriptions(testCase)
            matlabTable = table([1; 2], 'VariableNames', {'reward_size'});
            matlabTable.Properties.VariableDescriptions = {'Volume of the reward, in microliters'};

            dynamicTable = util.table2nwb(matlabTable);

            testCase.verifyEqual( ...
                dynamicTable.vectordata.get('reward_size').description, ...
                'Volume of the reward, in microliters')
        end
    end
end
