function fsstr = fillSetters(propnames, classprops, typeName, namespace)
fsstr = cell(size(propnames));
for i=1:length(propnames)
    nm = propnames{i};
    prop = classprops(nm);
    % The schema name (nm) may be a reserved MATLAB keyword; the setter and
    % validator reference the property by its valid identifier.
    id = file.internal.getMatlabPropertyName(nm);
    postsetFunctionStr = resolvePostsetFunction(nm, prop, typeName, namespace);
    if isempty(postsetFunctionStr)
        fsstr{i} = strjoin({...
            ['function set.' id '(obj, val)']...
            ['    obj.' id ' = obj.validate_' id '(val);'] ...
            'end'}, newline);
    else
        fsstr{i} = strjoin({...
            ['function set.' id '(obj, val)']...
            ['    obj.' id ' = obj.validate_' id '(val);'] ...
            ['    obj.postset_' id '()'], ...
            'end', ...
            postsetFunctionStr}, newline);
    end
end

fsstr = strjoin(fsstr, newline);
end

function postsetFunctionStr = resolvePostsetFunction(propName, prop, typeName, namespace)

    hookInfo = file.getPropertyHooks(propName, prop, typeName, namespace);
    postsetStatements = hookInfo.PostsetStatements;

    % The schema name (propName) may be a reserved MATLAB keyword; emitted
    % method/property identifiers use the valid identifier.
    propertyIdentifier = file.internal.getMatlabPropertyName(propName);

    if isa(prop, 'file.Attribute')

        if ~isempty(prop.dependent) && ~prop.readonly

            if ~isempty(prop.dependent_fullname)
                parentname = prop.dependent_fullname;
            else
                parentname = prop.dependent;
            end
            parentIdentifier = file.internal.getMatlabPropertyName(parentname);

            conditionStr = sprintf(...
                'if isempty(obj.%s) && ~isempty(obj.%s)', ...
                parentIdentifier, propertyIdentifier);

            warnIfDependencyMissingString = sprintf(...
                'obj.warnIfAttributeDependencyMissing(''%s'', ''%s'')', ...
                propName, parentname);

            postsetStatements = [postsetStatements, ...
                {conditionStr}, ...
                {file.addSpaces(warnIfDependencyMissingString, 4)}, ...
                {'end'}];
        end
    end

    if isempty(postsetStatements)
        postsetFunctionStr = '';
        return
    end

    postsetBody = strjoin(postsetStatements, newline);
    postsetLines = {sprintf('function postset_%s(obj)', propertyIdentifier), ...
        file.addSpaces(postsetBody, 4), ...
        'end'};
    postsetFunctionStr = strjoin(postsetLines, newline);
end
