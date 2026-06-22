classdef SchemaCategoryAlignedTable < tests.doubles.AlignedDynamicTableStub
    %SchemaCategoryAlignedTable Test double with one schema-defined category.

    properties
        categoryOne
    end

    methods
        function obj = SchemaCategoryAlignedTable(options)
            arguments
                options.Description (1,:) char = 'schema category table'
                options.IdData = []
                options.Categories = []
            end

            obj = obj@tests.doubles.AlignedDynamicTableStub( ...
                Description=options.Description, ...
                IdData=options.IdData, ...
                Categories=options.Categories);
        end

        function set.categoryOne(obj, value)
            types.util.checkType('categoryOne', 'types.hdmf_common.DynamicTable', value);
            obj.categoryOne = value;
            obj.postset_categoryOne()
        end

        function postset_categoryOne(obj)
            obj.syncNamedCategory('categoryOne');
        end
    end

    methods (Access = protected, Hidden)
        function categoryNames = getSchemaDefinedCategories(obj)
            categoryNames = getSchemaDefinedCategories@tests.doubles.AlignedDynamicTableStub(obj);
            localCategoryNames = "categoryOne";
            categoryNames = unique([categoryNames, localCategoryNames], 'stable');
        end
    end
end
