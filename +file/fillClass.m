function template = fillClass(name, namespace, processed, classprops, inherited, superClassProps)
    %name is the name of the scheme
    %namespace is the namespace context for this class

    %% PROCESSING
    class = processed(1);

    allProperties = keys(classprops);
    required = {};
    optional = {};
    readonly = {};
    defaults = {};
    dependent = {};
    
    %separate into readonly, required, and optional properties
    for iGroup = 1:length(allProperties)
        propertyName = allProperties{iGroup};
        prop = classprops(propertyName);

        isRequired = ischar(prop) || isa(prop, 'containers.Map') || isstruct(prop);
        isPropertyRequired = false;
        if isa(prop, 'file.interface.HasProps')
            isPropertyRequired = false(size(prop));
            for iProp = 1:length(prop)
                p = prop(iProp);
                isPropertyRequired(iProp) = p.required;
            end
        elseif isa(prop, 'file.Attribute')
            if isempty(prop.dependent)
                isRequired = prop.required;
            else
                isRequired = resolveRequiredForDependentProp(propertyName, prop, classprops);
            end
        elseif isa(prop, 'file.Link')
            isRequired = prop.required;
        end

        if isRequired || all(isPropertyRequired)
            required = [required {propertyName}];
        else
            optional = [optional {propertyName}];
        end

        if isa(prop, 'file.Attribute') || isa(prop, 'file.Dataset') 
            if prop.readonly
                readonly = [readonly {propertyName}];
            end

            if ~isempty(prop.value)
                if isa(prop, 'file.Attribute') 
                    defaults = [defaults {propertyName}];
                else % file.Dataset
                    if isRequired || all(isPropertyRequired)
                        defaults = [defaults {propertyName}];
                    end
                end
            end

            if isa(prop, 'file.Attribute') && ~isempty(prop.dependent)
                %extract prefix
                parentName = strrep(propertyName, ['_' prop.name], '');
                parent = classprops(parentName);
                if ~parent.required
                    dependent = [dependent {propertyName}];
                end
            end
        end
    end

    % Each property is emitted in exactly one properties block, with readonly
    % taking precedence over required/optional. Restrict each bucket to
    % non-inherited names and remove anything already going into the readonly
    % block to avoid duplicate property declarations.
    nonInherited = setdiff(allProperties, inherited);
    readonly = intersect(readonly, nonInherited);
    settable = setdiff(nonInherited, readonly);  % what's left for required/optional
    required = intersect(required, settable);
    optional = intersect(optional, settable);

    %% CLASSDEF
    superclassNames = {};
    if length(processed) <= 1
        superclassNames{1} = 'types.untyped.MetaClass'; %WRITE
    else
        parentName = processed(2).type; %WRITE
        superclassNames{1} = namespace.getFullClassName(parentName);
    end

    if isa(processed, 'file.Group')
        superclassNames{end+1} = 'types.untyped.GroupClass';
    else
        superclassNames{end+1} = 'types.untyped.DatasetClass';
    end

    if isa(class, 'file.Group') && class.hasAnonGroups
        superclassNames{end+1} = 'matnwb.mixin.HasUnnamedGroups';
    end

    if strcmp(name, 'AlignedDynamicTable')
        superclassNames{end+1} = 'matnwb.neurodata.AlignedDynamicTableBase';
    end

    %% return classfile string
    classDefinitionHeader = [...
        'classdef ' name ' < ' strjoin(superclassNames, ' & ') newline... %header, dependencies
        '% ' upper(name) ' - ' class.doc]; %name, docstr

    fullClassName = strjoin({'types', misc.str2validName(namespace.name), name}, '.');
    allRequiredPropertyNames = schemes.internal.getRequiredPropsForClass(fullClassName, namespace);
    if isempty(allRequiredPropertyNames)
        allRequiredPropertyNames = {'None'};
    end

    % Add list of required properties in class docstring
    classDefinitionHeader = [classDefinitionHeader, newline...
        '%', newline, ...
        '% Required Properties:', newline, ...
        sprintf('%%  %s', strjoin(allRequiredPropertyNames, ', '))];
 
    PropertyGroups = struct(...
        'Function', { ...
            @()file.fillProps(classprops, readonly, 'PropertyAttributes', 'SetAccess = protected'), ...
            @()file.fillProps(classprops, required, 'IsRequired', true), ...
            @()file.fillProps(classprops, optional)...
        }, ...
        'Separator', { ...
            '% READONLY PROPERTIES', ...
            '% REQUIRED PROPERTIES', ...
            '% OPTIONAL PROPERTIES' ...
        } ...
    );

    fullPropertyDefinition = '';
    for iGroup = 1:length(PropertyGroups)
        Group = PropertyGroups(iGroup);
        propertyDefinitionBody = Group.Function();
        if isempty(propertyDefinitionBody)
            continue;
        end
        fullPropertyDefinition = strjoin({...
            fullPropertyDefinition ...
            , Group.Separator ...
            , propertyDefinitionBody ...
            }, newline);
    end
    if isa(class, 'file.Group') && class.hasAnonGroups
        mixinPropertyBlock = createPropertyBlockForHasUnnamedGroupMixin(class);
        
        fullPropertyDefinition = strjoin(...
            {fullPropertyDefinition, mixinPropertyBlock}, newline);
    end

    constructorBody = file.fillConstructor(...
        name,...
        superclassNames{1},...
        defaults,... %all defaults, regardless of inheritance
        classprops,...
        namespace, ...
        superClassProps, ...
        class, ...
        inherited);
    setterFcns = file.fillSetters( ...
        setdiff(nonInherited, readonly), ...
        classprops, ...
        name, ...
        namespace);
    validatorFcns = file.fillValidators(allProperties, classprops, namespace, namespace.getFullClassName(name), inherited);
    exporterFcns = file.fillExport(nonInherited, class, superclassNames{1}, required, classprops);
    methodBody = strjoin({constructorBody...
        '%% SETTERS' setterFcns...
        '%% VALIDATORS' validatorFcns...
        '%% EXPORT' exporterFcns}, newline);

    customConstraintStr = file.fillCustomConstraint(name);
    if ~isempty(customConstraintStr)
        methodBody = strjoin({methodBody, '%% CUSTOM CONSTRAINTS', customConstraintStr}, newline);
    end

    if strcmp(name, 'DynamicTable')
        methodBody = strjoin({methodBody, '%% TABLE METHODS', file.fillDynamicTableMethods()}, newline);
    end

    fullMethodBody = strjoin({'methods' ...
        file.addSpaces(methodBody, 4) 'end'}, newline);
    schemaCategoryMethodBlock = createMethodBlockForAlignedDynamicTableCategories( ...
        classprops, nonInherited, name, namespace, superclassNames{1});
    readPolicyMethodBlock = fillReadPolicy(class, classprops);
    classSections = {classDefinitionHeader, fullPropertyDefinition, fullMethodBody};
    if ~isempty(schemaCategoryMethodBlock)
        classSections{end+1} = schemaCategoryMethodBlock;
    end
    if ~isempty(readPolicyMethodBlock)
        classSections{end+1} = readPolicyMethodBlock;
    end
    classSections{end+1} = 'end';
    template = strjoin(classSections, [newline newline]);
end

function readPolicyStr = fillReadPolicy(classInfo, classProps)
    eagerLoadPropertyNames = file.getEagerLoadPropertyNames(classInfo, classProps);
    if isempty(eagerLoadPropertyNames)
        readPolicyStr = '';
        return
    end

    quotedPropertyNames = strcat("'", string(eagerLoadPropertyNames), "'");
    propertyList = strjoin(quotedPropertyNames, newline);
    propertyList = file.addSpaces(char(propertyList), 12);

    readPolicyStr = strjoin({...
        '%% READ POLICY', ...
        'methods (Static, Hidden)', ...
        '    function propertyNames = getEagerLoadProperties()', ...
        '        propertyNames = {', ...
        propertyList, ...
        '        };', ...
        '    end', ...
        'end'}, newline);
end

function tf = resolveRequiredForDependentProp(propertyName, propInfo, allProps)
% resolveRequiredForDependentProp - If a dependent property is required,
% whether it is required on object level also depends on whether it's parent 
% property is required.
    if ~propInfo.required 
        tf = false;
    else % Check if parent is required
        parentName = strrep(propertyName, ['_' propInfo.name], '');
        parentInfo = allProps(parentName);
        tf = parentInfo.required;
    end
end

function propertyBlockStr = createPropertyBlockForHasUnnamedGroupMixin(classInfo)
    isAnonGroup = arrayfun(@(x) isempty(x.name), classInfo.subgroups, 'uni', true);
    anonNames = arrayfun(@(x) lower(x.type), classInfo.subgroups(isAnonGroup), 'uni', false);
    
    propertyBlockStr = strjoin({...
        'properties (Access = protected)', ...
        sprintf('    GroupPropertyNames = {%s}', strjoin(strcat('''', anonNames, ''''), ', ') ), ...
        'end'}, newline);
end

function methodBlockStr = createMethodBlockForAlignedDynamicTableCategories( ...
        classProps, propertyNames, className, namespace, superclassName)

    methodBlockStr = '';
    if ~file.internal.isDescendantOf(className, 'AlignedDynamicTable', namespace)
        return
    end

    categoryNames = string.empty(1, 0);
    for iProperty = 1:length(propertyNames)
        propertyName = propertyNames{iProperty};
        propertyInfo = classProps(propertyName);
        if isSchemaDefinedAlignedDynamicTableCategory(propertyInfo, namespace)
            categoryNames(end+1) = string(propertyName); %#ok<AGROW>
        end
    end

    if strcmp(className, 'AlignedDynamicTable')
        methodLines = { ...
            'function categoryNames = getSchemaDefinedCategories(obj)', ...
            '    categoryNames = getSchemaDefinedCategories@matnwb.neurodata.AlignedDynamicTableBase(obj);', ...
            'end'};
    else
        formattedNames = """" + categoryNames + """";
        if isempty(formattedNames)
            localCategoryLine = 'localCategoryNames = string.empty(1, 0);';
        else
            localCategoryLine = sprintf( ...
                'localCategoryNames = [%s];', strjoin(formattedNames, ', '));
        end

        methodLines = { ...
            'function categoryNames = getSchemaDefinedCategories(obj)', ...
            sprintf('    categoryNames = getSchemaDefinedCategories@%s(obj);', superclassName), ...
            sprintf('    %s', localCategoryLine), ...
            '    categoryNames = unique([categoryNames, localCategoryNames], ''stable'');', ...
            'end'};
    end

    methodBlockStr = strjoin({ ...
        'methods (Access = protected, Hidden)', ...
        file.addSpaces(strjoin(methodLines, newline), 4), ...
        'end'}, newline);
end

function tf = isSchemaDefinedAlignedDynamicTableCategory(propertyInfo, namespace)
    tf = isa(propertyInfo, 'file.Group') ...
        && ~propertyInfo.isConstrainedSet ...
        && ~isempty(propertyInfo.type) ...
        && file.internal.isDescendantOf(propertyInfo.type, 'DynamicTable', namespace);
end
