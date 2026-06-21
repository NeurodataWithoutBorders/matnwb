classdef SchemaCategoryAlignedTable < types.hdmf_common.AlignedDynamicTable
    %SchemaCategoryAlignedTable Test double with one schema-defined category.

    properties
        categoryOne
    end

    methods
        function obj = SchemaCategoryAlignedTable(varargin)
            obj = obj@types.hdmf_common.AlignedDynamicTable(varargin{:});
            obj.setupHasUnnamedGroupsMixin();
            types.util.aligneddynamictable.checkConfig(obj);
        end

        function set.categoryOne(obj, value)
            types.util.checkType('categoryOne', 'types.hdmf_common.DynamicTable', value);
            obj.categoryOne = value;
            obj.postset_categoryOne()
        end

        function postset_categoryOne(obj)
            types.util.aligneddynamictable.syncNamedCategory(obj, 'categoryOne');
        end
    end

    methods (Hidden)
        function categoryNames = getSchemaDefinedCategories(obj)
            categoryNames = getSchemaDefinedCategories@types.hdmf_common.AlignedDynamicTable(obj);
            localCategoryNames = "categoryOne";
            categoryNames = unique([categoryNames, localCategoryNames], 'stable');
        end
    end
end
