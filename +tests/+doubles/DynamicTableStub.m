classdef DynamicTableStub < types.hdmf_common.DynamicTable
    % DynamicTableStub - Minimal DynamicTable test double.

    methods
        function obj = DynamicTableStub(options)
            arguments
                options.Description (1,:) char = 'test table'
                options.IdData = []
            end

            obj = obj@types.hdmf_common.DynamicTable();
            obj.description = options.Description;

            if ~isempty(options.IdData)
                obj.id = tests.doubles.ElementIdentifiersStub( ...
                    Data=options.IdData);
            end
        end
    end
end
