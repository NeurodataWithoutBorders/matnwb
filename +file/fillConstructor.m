function functionString = fillConstructor(name, parentname, defaults, props, namespace)
    caps = upper(name);
    functionBody = ['% ' caps ' Constructor for ' name];

    bodyString = fillBody(parentname, defaults, props, namespace);
    if ~isempty(bodyString)
        functionBody = [functionBody newline() bodyString];
    end

    functionBody = strjoin({functionBody, ...
        sprintf('if strcmp(class(obj), ''%s'')', namespace.getFullClassName(name)), ...
        '    cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));', ...
        '    types.util.checkUnset(obj, unique(cellStringArguments));', ...
        'end'}, newline());

    % insert check for DynamicTable class and child classes
    bodyString = fillCheck(name, namespace);
    if ~isempty(bodyString)
        functionBody = [functionBody newline() bodyString];
    end

    functionString = strjoin({...
        ['function obj = ' name '(varargin)']...
        file.addSpaces(functionBody, 4)...
        'end'}, newline());

end

function bodystr = fillBody(parentName, defaults, props, namespace)
    if isempty(defaults)
        bodystr = '';
    else
        overridemap = containers.Map;
        for i=1:length(defaults)
            nm = defaults{i};
            if strcmp(props(nm).dtype, 'char')
                overridemap(nm) = ['''' props(nm).value ''''];
            else
                overridemap(nm) =...
                    sprintf('types.util.correctType(%d, ''%s'')',...
                    props(nm).value,...
                    props(nm).dtype);
            end
        end
        kwargs = io.map2kwargs(overridemap);
        %add surrounding quotes to kwargs so misc.cellPrettyPrint can print them correctly
        kwargs(1:2:end) = strcat('''', kwargs(1:2:end), '''');
        bodystr = ['varargin = [{' misc.cellPrettyPrint(kwargs) '} varargin];' newline];
    end
    bodystr = [bodystr 'obj = obj@' parentName '(varargin{:});'];

    names = keys(props);
    if isempty(names)
        return;
    end
    % if there's a root object that is a constrained set, let it be hoistable from dynamic arguments
    dynamicConstrained = false(size(names));
    isAnonymousType = false(size(names));
    isAttribute = false(size(names));
    typenames = repmat({''}, size(names));
    varnames = repmat({''}, size(names));
    for i = 1:length(names)
        nm = names{i};
        prop = props(nm);

        if isa(prop, 'file.Attribute')
            isAttribute(i) = true;
            continue;
        end

        if isa(prop, 'file.interface.HasProps')
            isDynamicConstrained = false(size(prop));
            isAnon = false(size(prop));
            hasType = false(size(prop));
            typeNames = cell(size(prop));
            for iProp = 1:length(prop)
                p = prop(iProp);
                isDynamicConstrained(iProp) = p.isConstrainedSet && strcmpi(nm, p.type);
                isAnon(iProp) = ~p.isConstrainedSet && isempty(p.name);
                hasType(iProp) = ~isempty(p.type);
                typeNames{iProp} = p.type;
            end
            dynamicConstrained(i) = all(isDynamicConstrained);
            isAnonymousType(i) = all(isAnon);

            if all(hasType)
                varnames{i} = nm;
                typeNameCell = cell(size(prop));
                try
                    for iProp = 1:length(prop)
                        typeNameCell{iProp} = namespace.getFullClassName(prop(iProp).type);
                    end
                catch ME
                    if ~strcmp(ME.identifier, 'NWB:Scheme:Namespace:NotFound')
                        rethrow(ME);
                    end
                end
                typenames{i} = misc.cellPrettyPrint(typeNameCell);
            end
        end
    end

    %warn for missing namespaces/property types
    warnmsg = ['`' parentName '`''s constructor is unable to check for type `%1$s` ' ...
        'because its namespace or type specifier could not be found.  Try generating ' ...
        'the namespace or class definition for type `%1$s` or fix its schema.'];

    invalid = cellfun('isempty', typenames);
    invalidWarn = invalid & (dynamicConstrained | isAnonymousType) & ~isAttribute;
    invalidVars = varnames(invalidWarn);
    for i=1:length(invalidVars)
        warning(warnmsg, invalidVars{i});
    end
    varnames = lower(varnames);

    %we delete the entry in varargin such that any conflicts do not show up in inputParser
    deleteFromVars = 'varargin(ivarargin) = [];';
    %if constrained/anon sets exist, then check for nonstandard parameters and add as
    %container.map
    constrainedTypes = typenames(dynamicConstrained & ~invalid);
    constrainedVars = varnames(dynamicConstrained & ~invalid);
    methodCalls = strcat('[obj.', constrainedVars, ', ivarargin] = ',...
        ' types.util.parseConstrained(obj,''', constrainedVars, ''', ''',...
        constrainedTypes, ''', varargin{:});');
    fullBody = cell(length(methodCalls) * 2,1);
    fullBody(1:2:end) = methodCalls;
    fullBody(2:2:end) = {deleteFromVars};
    fullBody = strjoin(fullBody, newline);
    bodystr(end+1:end+length(fullBody)+1) = [newline fullBody];

    %if anonymous values exist, then check for nonstandard parameters and add
    %as Anon

    anonTypes = typenames(isAnonymousType & ~invalid);
    anonVars = varnames(isAnonymousType & ~invalid);
    methodCalls = strcat('[obj.', anonVars, ',ivarargin] = ',...
        ' types.util.parseAnon(''', anonTypes, ''', varargin{:});');
    fullBody = cell(length(methodCalls) * 2,1);
    fullBody(1:2:end) = methodCalls;
    fullBody(2:2:end) = {deleteFromVars};
    fullBody = strjoin(fullBody, newline);
    bodystr(end+1:end+length(fullBody)+1) = [newline fullBody];

    parser = {...
        'p = inputParser;',...
        'p.KeepUnmatched = true;',...
        'p.PartialMatching = false;',...
        'p.StructExpand = false;'};

    names = names(~dynamicConstrained & ~isAnonymousType);
    defaults = cell(size(names));
    for i=1:length(names)
        prop = props(names{i});
        isPluralSet = isa(prop, 'file.interface.HasProps') && ~isscalar(prop);
        isGroupSet = ~isPluralSet ...
        && isa(prop, 'file.Group') ...
        && (prop.hasAnonData || prop.hasAnonGroups || prop.isConstrainedSet);
        isDataSet = ~isPluralSet ...
            && isa(prop, 'file.Dataset')...
            && prop.isConstrainedSet;
        if isPluralSet || isGroupSet || isDataSet
            defaults{i} = 'types.untyped.Set()';
        else
            defaults{i} = '[]';
        end
    end
    % add parameters
    parser = [parser, strcat('addParameter(p, ''', names, ''', ', defaults,');')];
    % parse
    parser = [parser, {'misc.parseSkipInvalidName(p, varargin);'}];
    % get results
    parser = [parser, strcat('obj.', names, ' = p.Results.', names, ';')];
    parser = strjoin(parser, newline);
    bodystr(end+1:end+length(parser)+1) = [newline parser];
end

function checkTxt = fillCheck(name, namespace)
    checkTxt = [];

    % find if a dynamic table ancestry exists
    ancestry = namespace.getRootBranch(name);
    isDynamicTableDescendent = false;
    for iAncestor = 1:length(ancestry)
        ParentRaw = ancestry{iAncestor};
        % this is always true, we just use the proper index as typedefs may vary.
        typeDefInd = isKey(ParentRaw, namespace.TYPEDEF_KEYS);
        isDynamicTableDescendent = isDynamicTableDescendent ...
            || strcmp('DynamicTable', ParentRaw(namespace.TYPEDEF_KEYS{typeDefInd}));
    end

    if ~isDynamicTableDescendent
        return;
    end

    checkTxt = strjoin({ ...
        sprintf('if strcmp(class(obj), ''%s'')', namespace.getFullClassName(name)), ...
        '    types.util.dynamictable.checkConfig(obj);', ...
        'end',...
        }, newline);
end