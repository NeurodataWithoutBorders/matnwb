classdef AlignedDynamicTableStub < tests.doubles.DynamicTableStub ...
        & matnwb.mixin.HasUnnamedGroups & matnwb.neurodata.AlignedDynamicTableBase
    % AlignedDynamicTableStub - Minimal AlignedDynamicTable test double.

    properties (Access = protected, Transient)
        GroupPropertyNames = "dynamictable"
    end

    properties
        categories
        dynamictable
    end

    methods
        function obj = AlignedDynamicTableStub(options)
            arguments
                options.Description (1,:) char = 'aligned table'
                options.IdData = []
                options.Categories = []
            end

            obj = obj@tests.doubles.DynamicTableStub( ...
                Description=options.Description, ...
                IdData=options.IdData);

            obj.categories = options.Categories;
            obj.dynamictable = types.untyped.Set();
            obj.setupHasUnnamedGroupsMixin();
            obj.ensureAlignedTableConsistency();
        end

        function set.categories(obj, value)
            obj.categories = obj.validate_categories(value);
        end

        function set.dynamictable(obj, value)
            obj.dynamictable = obj.validate_dynamictable(value);
        end

        function value = validate_categories(obj, value)
            value = types.util.checkDtype('categories', 'char', value);
            types.util.validateShape('categories', {Inf}, value)
            value = obj.validateCategories(value);
        end

        function value = validate_dynamictable(~, value)
            namedProperties = struct();
            constrainedTypes = {'types.hdmf_common.DynamicTable'};
            types.util.checkSet( ...
                'dynamictable', namedProperties, constrainedTypes, value);
        end
    end
end
