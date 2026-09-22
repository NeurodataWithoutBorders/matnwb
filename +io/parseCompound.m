function data = parseCompound(datasetId, data, isScalar)
    %did is the dataset_id for the containing dataset
    %data should be a scalar struct with fields as columns
    if nargin < 3; isScalar = false; end
    typeId = H5D.get_type(datasetId);
    if isempty(data)
        % A dataset holding no rows is read back as a 0x0 struct without any
        % fields, so the columns have to be rebuilt from the compound type in
        % order to keep the member names and their types.
        data = emptyCompoundData(typeId);
        H5T.close(typeId)
        return;
    end
    numFields = H5T.get_nmembers(typeId);
    subTypeId = cell(1, numFields);
    isReferenceType = false(1, numFields);
    isCharacterType = false(1, numFields);
    isLogicalType = false(1,numFields);
    isScalarCellStr = false(1,numFields);
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
                isScalarCellStr(iField) = isScalar && ~isCharacterType(iField);
            case H5ML.get_constant_value('H5T_ENUM')
                isLogicalType(iField) = io.isBool(fieldTypeId);
                % Note: There is currently no postprocessing applied for
                % other ENUMs when parsing compound data types. 
                % Should be fine as NWB only uses the ENUM class for booleans.
            otherwise
                %do nothing
        end
    end
    H5T.close(typeId)

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

    % Close type ids
    for i = 1:numel(subTypeId)
        H5T.close(subTypeId{i})
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
        data.(name) = io.internal.h5.postprocess.toLogical(data.(name));
    end

    % unpack scalar cellstr
    scalarCellstrFieldName = fieldName(isScalarCellStr);
    for iFieldName = 1:length(scalarCellstrFieldName)
        name = scalarCellstrFieldName{iFieldName};
        data.(name) = data.(name){1};
    end
end

function data = emptyCompoundData(typeId)
% emptyCompoundData - Build a scalar struct of empty, typed columns.
    data = struct();
    numFields = H5T.get_nmembers(typeId);
    for iField = 1:numFields
        name = H5T.get_member_name(typeId, iField-1);
        fieldTypeId = H5T.get_member_type(typeId, iField-1);
        matlabType = io.getMatType(fieldTypeId);
        H5T.close(fieldTypeId)
        data.(name) = emptyColumn(matlabType);
    end
end

function column = emptyColumn(matlabType)
% emptyColumn - Empty column of the MATLAB type a compound member maps to.
    switch matlabType
        case {'char', 'cell'}
            % Variable length strings and non-boolean enums are read as one
            % character vector per row.
            column = cell(0, 1);
        case 'logical'
            column = false(0, 1);
        otherwise
            % Numeric types and the reference wrapper classes all construct an
            % empty instance from their class name.
            column = feval([matlabType '.empty'], 0, 1);
    end
end
