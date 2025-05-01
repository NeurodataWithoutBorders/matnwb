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
    hidden = {}; % special hidden properties for hard-coded workarounds
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

            if strcmp(namespace.name, 'hdmf_common') ...
                && strcmp(name, 'VectorData') ...
                && any(strcmp(prop.name, {'unit', 'sampling_rate', 'resolution'}))
                hidden{end+1} = propertyName;
            end
        end
    end
    nonInherited = setdiff(allProperties, inherited);
    readonly = intersect(readonly, nonInherited);
    exclusivePropertyGroups = union(readonly, hidden);
    required = setdiff(intersect(required, nonInherited), exclusivePropertyGroups);
    optional = setdiff(intersect(optional, nonInherited), exclusivePropertyGroups);

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
 
    hiddenAndReadonly = intersect(hidden, readonly);
    hidden = setdiff(hidden, hiddenAndReadonly);
    readonly = setdiff(readonly, hiddenAndReadonly);
    PropertyGroups = struct(...
        'Function', {...
        @()file.fillProps(classprops, hiddenAndReadonly, 'PropertyAttributes', 'Hidden, SetAccess = protected') ...
        , @()file.fillProps(classprops, hidden, 'PropertyAttributes', 'Hidden') ...
        , @()file.fillProps(classprops, readonly, 'PropertyAttributes', 'SetAccess = protected') ...
        , @()file.fillProps(classprops, required, 'IsRequired', true) ...
        , @()file.fillProps(classprops, optional)...
        } ...
        , 'Separator', { ...
        '% HIDDEN READONLY PROPERTIES' ...
        , '% HIDDEN PROPERTIES' ...
        , '% READONLY PROPERTIES' ...
        , '% REQUIRED PROPERTIES' ...
        , '% OPTIONAL PROPERTIES' ...
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
        class);
    setterFcns = file.fillSetters(setdiff(nonInherited, union(readonly, hiddenAndReadonly)), classprops);
    validatorFcns = file.fillValidators(allProperties, classprops, namespace, namespace.getFullClassName(name), inherited);
    exporterFcns = file.fillExport(nonInherited, class, superclassNames{1}, required);
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
    template = strjoin({classDefinitionHeader fullPropertyDefinition fullMethodBody 'end'}, ...
        [newline newline]);
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
