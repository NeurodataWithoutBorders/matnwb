classdef DynamicFilter < types.untyped.datapipe.Property

    properties (SetAccess = private)
        dynamicFilter;
    end

    properties
        parameters;
    end

    methods
        function obj = DynamicFilter(filter, parameters)
            arguments
                filter (1,1) types.untyped.datapipe.dynamic.Filter
                parameters = []
            end

            assert(~verLessThan('matlab', '9.12'), ...
                ['Your MATLAB version `%s` does not support writing with ' ...
                'dynamically loaded filters. Please upgrade to version R2022a ' ...
                'or higher in order to use this feature.'], version); %#ok<VERLESSMATLAB>
            assert(H5Z.filter_avail(uint32(filter)), ...
                ['Filter `%s` does not appear to be installed on this system. ' ...
                'Please doublecheck `%s` for more information about writing ' ...
                'with third-party filters.'], ...
                filter, ...
                'https://www.mathworks.com/help/matlab/import_export/read-and-write-hdf5-datasets-using-dynamically-loaded-filters.html');

            obj.dynamicFilter = filter;
            obj.parameters = parameters;
        end

        function tf = isInDcpl(obj, dcpl)
            tf = false;

            for i = 0:(H5P.get_nfilters(dcpl) - 1)
                [id, ~, ~, ~, ~] = H5P.get_filter(dcpl, i);
                if id == uint32(obj.dynamicFilter)
                    tf = true;
                    return;
                end
            end
        end

        function addTo(obj, dcpl)
            H5P.set_filter( ...
                dcpl, ...
                uint32(obj.dynamicFilter), ...
                'H5Z_FLAG_MANDATORY', ...
                obj.parameters);
        end
    end
end
