function data = parseCompound(datasetId, data)
    %did is the dataset_id for the containing dataset
    %data should be a scalar struct with fields as columns
    if isempty(data)
        return;
    end
    typeId = H5D.get_type(datasetId);
    numFields = H5T.get_nmembers(typeId);
    subTypeId = cell(1, numFields);
    isReferenceType = false(1, numFields);
    isCharacterType = false(1, numFields);
    isLogicalType = false(1,numFields);
    for iField = 1:numFields
        fieldTypeId = H5T.get_member_type(typeId, iField-1);
        subTypeId{iField} = fieldTypeId;
        switch H5T.get_member_class(typeId, iField-1)
            case H5ML.get_constant_value('H5T_REFERENCE')
                isReferenceType(iField) = true;
            case H5ML.get_constant_value('H5T_STRING')
                %if not variable len (which would make it a cell array)
                %then mark for transpose
                isCharacterType(iField) = ~H5T.is_variable_str(fieldTypeId);
            case H5ML.get_constant_value('H5T_ENUM')
                isLogicalType(iField) = io.isBool(fieldTypeId);
            otherwise
                %do nothing
        end
    end

    fieldName = fieldnames(data);

    % resolve references by column
    referenceTypeId = subTypeId(isReferenceType);
    referenceFieldName = fieldName(isReferenceType);
    for iFieldName = 1:length(referenceFieldName)
        name = referenceFieldName{iFieldName};
        rawReference = data.(name);
        rawTypeId = referenceTypeId{iFieldName};
        data.(name) = io.parseReference(datasetId, rawTypeId, rawReference);
    end

    % transpose character arrays because they are column-ordered
    % when read
    characterFieldName = fieldName(isCharacterType);
    for iFieldName = 1:length(characterFieldName)
        name = characterFieldName{iFieldName};
        data.(name) = data.(name) .';
    end

    % convert column data to proper logical arrays/matrices
    logicalFieldName = fieldName(isLogicalType);
    for iFieldName = 1:length(logicalFieldName)
        name = logicalFieldName{iFieldName};
        data.(name) = strcmp('TRUE', data.(name));
    end
end