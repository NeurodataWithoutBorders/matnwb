classdef ElementIdentifiersStub < types.hdmf_common.ElementIdentifiers
    % ElementIdentifiersStub - Minimal ElementIdentifiers test double.

    methods
        function obj = ElementIdentifiersStub(options)
            arguments
                options.Data = []
            end

            obj = obj@types.hdmf_common.ElementIdentifiers('data', options.Data);
        end
    end
end
