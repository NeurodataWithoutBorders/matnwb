classdef DynamicFilter < types.untyped.datapipe.Property
    %DYNAMIC Summary of this class goes here
    %   Detailed explanation goes here

    properties (SetAccess = private)
        dynamicFilter;
    end

    methods
        function obj = DynamicFilter(filter)
            validateattributes( ...
                filter, ...
                {'types.untyped.datapipe.dynamic.Filter'}, ...
                {'scalar'}, ...
                'DynamicFilter', 'filter');
            obj.dynamicFilter = filter;
        end

        function tf = isInDcpl(dcpl)
            tf = false;

            for i = 0:(H5P.get_nfilters(dcpl) - 1)
                [id, ~, ~, ~, ~] = H5P.get_filter(dcpl, i);
                if id == uint32(obj.dynamicFilter)
                    tf = true;
                    return;
                end
            end
        end

        function addTo(obj, dcpl, parameters)
            if nargin < 3
                parameters = [];
            end

            H5P.set_filter( ...
                dcpl, ...
                uint32(obj.dynamicFilter), ...
                'H5Z_FLAG_MANDATORY', ...
                parameters);
        end
    end
end