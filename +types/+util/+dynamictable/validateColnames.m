function colnames = validateColnames(colnames)
% VALIDATECOLNAMES Validate and normalize DynamicTable column names.
%
% Input can be a cell array of character vectors, a string array or a
% character vector. Output is a cell array of character vectors.

    if ~types.util.dynamictable.internal.isColnamesTextContainer(colnames) ...
            && matnwb.common.validation.isReadContext()
        return
    end

    colnames = types.util.dynamictable.normalizeColnames(colnames);
    types.util.dynamictable.validateUniqueColnames(colnames);
end
