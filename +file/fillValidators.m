function validationStr = fillValidators(propnames, props, namespaceReg, className, inherited)
    validationStr = '';
    for i=1:length(propnames)
        nm = propnames{i};
        prop = props(nm);

        if file.internal.isPropertyReadonly(prop) && ~isempty(prop.value)
            % Need to add a validator for inherited and readonly properties. In 
            % the superclass these properties might not be read-only and due to
            % inheritance rules in MATLAB it is not possible to change property 
            % attributes of a property from public (in a superclass) to 
            % protected (in a subclass).
            if any(strcmp(nm, inherited))
                validationBody = fillReadOnlyValidation(nm, prop.value, className);
            else
                continue
            end
        elseif startsWith(class(prop), 'file.') % HDMF primitive type
            validationBody = fillUnitValidation(nm, prop, namespaceReg);
        else % MATLAB primitive type
            validationBody = fillDtypeValidation(nm, prop, namespaceReg);
        end

        headerStr = ['function val = validate_' nm '(obj, val)'];
        if isempty(validationBody)
            functionStr = [headerStr newline 'end'];
        else
            functionStr = strjoin({headerStr ...
                file.addSpaces(strtrim(validationBody), 4) 'end'}, newline);
        end
        validationStr = strcat(validationStr, [newline, functionStr]);
    end
end

function unitValidationStr = fillUnitValidation(name, prop, namespaceReg)
    unitValidationStr = '';
    if ~isscalar(prop) || (isa(prop, 'file.Link') && prop.isConstrainedSet)
        constrained = cell(size(prop));
        for iProp = 1:length(prop)
            p = prop(iProp);
            assert(p.isConstrainedSet && ~isempty(p.type), 'Non-constrained anonymous set?');
            constrained{iProp} = ['''', namespaceReg.getFullClassName(p.type), ''''];
        end
        
        unitValidationStr = strjoin({...
            unitValidationStr, ...
            ['constrained = {', strjoin(constrained, ', '), '};'], ...
            ['types.util.checkSet(''', name, ''', struct(), constrained, val);'], ...
            }, newline);
    elseif isa(prop, 'file.Dataset')
        unitValidationStr = fillDatasetValidation(name, prop, namespaceReg);
    elseif isa(prop, 'file.Group')
        unitValidationStr = fillGroupValidation(name, prop, namespaceReg);
    elseif isa(prop, 'file.Attribute')
        unitValidationStr = strjoin({unitValidationStr...
            fillDtypeValidation(name, prop.dtype, namespaceReg)...
            fillDimensionValidation(name, prop.shape)...
            }, newline);
    elseif isa(prop, 'file.Link') % Link
        unitValidationStr = fillLinkValidation(name, prop, namespaceReg);
    else
        error('NWB:InternalError', 'Unexpected property specification')
    end
end

function unitValidationStr = fillGroupValidation(name, prop, namespaceReg)
    if ~isempty(prop.type) && ~prop.isConstrainedSet
        fullTypeName = namespaceReg.getFullClassName(prop.type);
        unitValidationStr = fillDtypeValidation(name, fullTypeName, namespaceReg);
        return;
    end

    namedprops = struct();
    constraints = {};
    if isempty(prop.type)
        warning('NWB:FillValidators:ValidationNotImplemented', ...
            ['Detected a group-based data type (''%s'') with an untyped ', ...
            'subgroup. Validation logic for checking shape or quantity ', ...
            'of nested elements is not implemented '], prop.name)

        %% process datasets
        % if type, check if constrained
        %   if constrained, add to constr
        %   otherwise, check type once
        % otherwise, check dtype
        for iDataset = 1:length(prop.datasets)
            dataset = prop.datasets(iDataset);

            if isempty(dataset.type)
                namedprops.(dataset.name) = dataset.dtype;
            else
                type = namespaceReg.getFullClassName(dataset.type);
                if dataset.isConstrainedSet
                    constraints{end+1} = type;
                else
                    namedprops.(dataset.name) = type;
                end
            end
        end

        %% process groups
        % if type, check if constrained
        %   if constrained, add to constr
        %   otherwise, check type once
        % otherwise, error.  This shouldn't happen.
        for iSubGroup = 1:length(prop.subgroups)
            subGroup = prop.subgroups(iSubGroup);
            assert(~isempty(subGroup.type), 'Unsupported case with two nested untyped groups');
            subGroupFullName = namespaceReg.getFullClassName(subGroup.type);

            if isempty(subGroup.name)
                constraints{end+1} = subGroupFullName;
            else
                namedprops.(subGroup.name) = subGroupFullName;
            end
        end

        %% process attributes
        for iAttribute = 1:length(prop.attributes)
            Attribute = prop.attributes(iAttribute);
            namedprops.(Attribute.name) = Attribute.dtype;
        end

        %% process links
        for iLink = 1:length(prop.links)
            Link = prop.links(iLink);
            namespace = namespaceReg.getNamespace(Link.type);
            namedprops.(Link.name) = char(matnwb.common.composeFullClassName(namespace.name, Link.type));
        end
    else
        constraints{end+1} = namespaceReg.getFullClassName(prop.type);
    end

    %% create unit validation string

    propnames = fieldnames(namedprops);
    unitValidationStr = 'namedprops = struct();';
    for i=1:length(propnames)
        nm = propnames{i};
        unitValidationStr = strjoin({unitValidationStr...
            ['namedprops.' nm ' = ''' namedprops.(nm) ''';']}, newline);
    end

    for iConstraint = 1:length(constraints)
        constraints{iConstraint} = ['''', constraints{iConstraint}, ''''];
    end

    unitValidationStr = strjoin({...
        unitValidationStr, ...
        ['constrained = {', strjoin(constraints, ','), '};'], ...
        ['types.util.checkSet(''', name, ''', namedprops, constrained, val);'], ...
        }, newline);
end

function unitValidationStr = fillDatasetValidation(name, prop, namespaceReg)
    
    unitValidationStr = '';
    validationLines = {};

    if prop.isConstrainedSet
        fullname = getFullClassName(namespaceReg, prop.type, name);
        if isempty(fullname)
            return
        end

        validationLines = [validationLines ...
            {['constrained = { ''' fullname ''' };']} ...
            {['types.util.checkSet(''' name ''', struct(), constrained, val);']} ...
            ];
    else
        if ~isempty(prop.type) % Dataset class like e.g. VectorData
            fullname = getFullClassName(namespaceReg, prop.type, name);
            if isempty(fullname)
                return
            end

            validationLines = [validationLines ...
                {fillTypeValidation(name, fullname)}];

            datasetValidationLines = [...
                {fillDtypeValidation(name, prop.dtype, namespaceReg)}, ...
                {fillDimensionValidation(name, prop.shape)} ];

            datasetValidationLines(cellfun('isempty', datasetValidationLines)) = [];
            datasetValidationLines = indentLines(datasetValidationLines, 4);

            if ~isempty(datasetValidationLines)
                validationLines{end+1} = 'if ~isempty(val)';
                validationLines{end+1} = '    [val, originalVal] = types.util.unwrapValue(val);';
                validationLines = [validationLines, datasetValidationLines];
                validationLines{end+1} = '    val = types.util.rewrapValue(val, originalVal);';
                validationLines{end+1} = 'end';
            end
        else
            validationLines = [validationLines ...
                {fillDtypeValidation(name, prop.dtype, namespaceReg)} ...
                {fillDimensionValidation(name, prop.shape)} ];
        end
    end
    validationLines(cellfun('isempty', validationLines)) = [];
    unitValidationStr = strjoin(validationLines, newline);
end

function validationStr = fillLinkValidation(name, prop, namespaceReg)
    fullName = namespaceReg.getFullClassName(prop.type);
    
    validationStr = sprintf(...
        'val = types.util.validateSoftLink(''%s'', val, ''%s'');', ...
        name, fullName);
end

function fdvstr = fillDimensionValidation(name, shape)
    
    if isnumeric(shape) && isnan(shape) % Any shape is allowed
        fdvstr = ''; return
    end

    if isnumeric(shape) && isnan(shape) % Any shape is allowed
        fdvstr = ''; return
    end

    if iscell(shape)
        if ~isempty(shape) && iscell(shape{1})
            for i = 1:length(shape)
                for j = 1:length(shape{i})
                    shape{i}{j} = num2str(shape{i}{j});
                end
                shape{i} = ['[' strjoin(shape{i}, ',') ']'];
            end
            validShapeStr = ['{' strjoin(shape, ', ') '}'];
        else
            for i = 1:length(shape)
                shape{i} = num2str(shape{i});
            end
            validShapeStr = ['{[' strjoin(shape, ',') ']}'];
        end
    else
        validShapeStr = ['{[' num2str(shape) ']}'];
    end

    fdvstr = sprintf('types.util.validateShape(''%s'', %s, val)', name, validShapeStr);
end

function validationStr = fillTypeValidation(name, type)
    validationStr = ['types.util.checkType(''' name ''', ''' type ''', val);'];
end

%NOTE: can return empty strings
function fdvstr = fillDtypeValidation(name, type, namespaceReg)
    if isstruct(type)
        fnames = fieldnames(type);
        fdvstr = strjoin({...
            'if isempty(val)'...
            '    % skip validation for empty values'...
            'else'...
            '    vprops = struct();'...
            }, newline);
        vprops = cell(length(fnames),1);
        for i=1:length(fnames)
            nm = fnames{i};
            if isReferenceType(type.(nm))
                typeval = getReferenceTypeClassName(type.(nm));
            else
                typeval = type.(nm);
            end
            vprops{i} = ['    vprops.' nm ' = ''' typeval ''';'];
        end
        fdvstr = [fdvstr, newline, strjoin(vprops, newline), newline, ...
            '    val = types.util.checkDtype(''' name ''', vprops, val);' ...
            newline, 'end'];
    elseif isReferenceType(type)
        fdvstr = fillReferenceTypeValidation(name, type, namespaceReg);
    else
        fdvstr = '';
        if strcmp(type, 'any')
            fdvstr = '';
            return;
        else
            ts = strrep(type, '-', '_');
        end
        fdvstr = [fdvstr ...
            'val = types.util.checkDtype(''' name ''', ''' ts ''', val);'];
    end
end

function validationStr = fillReferenceTypeValidation(name, typeSpec, namespaceReg)

    fullReferenceClassName = getReferenceTypeClassName(typeSpec);

    % Get full class name for target type
    targetType = typeSpec('target_type');
    fullTargetTypeName = namespaceReg.getFullClassName(targetType);

    validationLines = {...
        sprintf('%% Reference to type `%s`', targetType), ...
        sprintf('val = types.util.validateReferenceType(''%s'', val, ''%s'', ''%s'');', ...
        name, fullTargetTypeName, fullReferenceClassName)
        };

    validationStr = strjoin(validationLines, newline);
end

function fdvstr = fillReadOnlyValidation(name, value, className)

    classNameSplit = strsplit(className, '.');
    shortName = classNameSplit{end};
    %errorStr = sprintf( 'error(''NWB:Type:ReadOnlyProperty'', ''Unable to set the ''''%s'''' property of class ''''<a href="matlab:doc %s">%s</a>'''' because it is read-only.'')', name, className, shortName);  
    errorStr = sprintf( 'warning(''NWB:Type:ReadOnlyProperty'', ''The ''''%s'''' property of class ''''<a href="matlab:doc %s">%s</a>'''' is invalid according to the NWB schema.'')', name, className, shortName); 
    if ischar(value)
        condition = strjoin({ ...
            sprintf('if isequal(val, ''%s'')', value), ...
            sprintf('    val = ''%s'';', value ), ...
                    'else' }, newline);
    elseif isnumeric(value) || islogical(value)
        condition = strjoin({ ...
            sprintf('if isequal(val, %d)', value), ...
            sprintf('    val = %d;', value ), ...
                    'else' }, newline);
    else
        % Note: According to the documentation for Attribute specification keys
        % (https://schema-language.readthedocs.io/en/latest/description.html#sec-attributes-spec),
        % the above cases should be sufficient.
        error('NWB:ClassGenerator:ReadOnlyValidatorNotImplemented', ...
            'Read-only validator is not implemented for values of type "%s"', class(value))
    end
    
    fdvstr = strjoin({...
            condition, ...
            sprintf('    %s', errorStr), ...
            'end' }, newline );
end

function fullname = getFullClassName(namespaceReg, propType, name)
    fullname = '';
    try
        fullname = namespaceReg.getFullClassName(propType);
    catch ME
        if ~endsWith(ME.identifier, 'Namespace:NotFound')
            rethrow(ME);
        end

        warning('NWB:Fill:Validators:NamespaceNotFound',...
            ['Namespace could not be found for type `%s`.' ...
            '  Skipping Validation for property `%s`.'], propType, name);
    end
end

function tf = isReferenceType(typeSpec)
    % If the type specification is a containers.Map type, the type will be
    % a reference type, i.e an object view or region view.
    tf = isa(typeSpec, 'containers.Map');
    if tf
        assert(isKey(typeSpec, 'target_type'), ...
            'Expected type specification to have the `target_type` key')
        assert(isKey(typeSpec, 'reftype'), ...
            'Expected type specification to have the reftype key')
    end
end

function fullReferenceClassName = getReferenceTypeClassName(typeSpec)
    assert(isKey(typeSpec, 'reftype'), 'Expected reftype key')
    switch typeSpec('reftype')
        case 'region'
            referenceClassName = 'RegionView';
        case 'object'
            referenceClassName = 'ObjectView';
    end
    fullReferenceClassName = ['types.untyped.' referenceClassName];
end

function indentedLines = indentLines(lines, numIndents)
    if iscell(lines)
        indentedLines = cellfun(@(c) indentSingle(c, numIndents), lines);
    else
        indentedLines = indentSingle(lines, numIndents);
    end

    function indentedLine = indentSingle(line, numIndents)
        splitLine = split(line, newline);
        splitLine = strcat({repmat(' ', 1, numIndents)}, splitLine);
        indentedLine = join(splitLine, newline);
    end
end
