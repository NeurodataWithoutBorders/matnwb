function addTableColumn(dynamicTable, subTable)
    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
        subTable table
    end

    error('NWB:DynamicTable', ...
        ['Using MATLAB tables as input to the addColumn DynamicTable method has '...
        'been deprecated. Please, use key-value pairs instead'])
end
