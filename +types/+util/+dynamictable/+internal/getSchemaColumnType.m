function columnClassName = getSchemaColumnType(dynamicTable, columnName)
% getSchemaColumnType - Return the class that the schema requires for a column.
%
% Generated DynamicTable classes list, in the private constant
% DeclaredSchemaColumnTypes, the class of each of their own columns that the
% schema declares as a subtype of VectorData. This function searches the
% class of the table and then its superclasses, and returns the first class
% name listed for the column.
%
% The output is empty for a column that is a plain VectorData, for a column
% that the schema does not define, and for a table whose class lists no
% column types.

    arguments
        dynamicTable
        columnName (1,:) char
    end

    columnClassName = '';
    classNames = [{class(dynamicTable)}; superclasses(dynamicTable)];
    for iClass = 1:numel(classNames)
        metaClass = meta.class.fromName(classNames{iClass});
        propertyList = metaClass.PropertyList;
        if isempty(propertyList)
            continue
        end

        % The property list of a class can include a private property of a
        % superclass, so the defining class is compared as well.
        isDeclaration = strcmp({propertyList.Name}, 'DeclaredSchemaColumnTypes') ...
            & [propertyList.DefiningClass] == metaClass;
        if ~any(isDeclaration)
            continue
        end

        columnTypes = propertyList(isDeclaration).DefaultValue;
        if isfield(columnTypes, columnName)
            columnClassName = columnTypes.(columnName);
            return
        end
    end
end
