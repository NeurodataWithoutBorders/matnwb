function fsstr = fillSetters(propnames, classprops, typeName, namespace)
fsstr = cell(size(propnames));
for i=1:length(propnames)
    nm = propnames{i};
    prop = classprops(nm);
    postsetFunctionStr = resolvePostsetFunction(nm, prop, typeName, namespace);
    if isempty(postsetFunctionStr)
        fsstr{i} = strjoin({...
            ['function set.' nm '(obj, val)']...
            ['    obj.' nm ' = obj.validate_' nm '(val);'] ...
            'end'}, newline);
    else
        fsstr{i} = strjoin({...
            ['function set.' nm '(obj, val)']...
            ['    obj.' nm ' = obj.validate_' nm '(val);'] ...
            ['    obj.postset_' nm '()'], ...
            'end', ...
            postsetFunctionStr}, newline);
    end
end

fsstr = strjoin(fsstr, newline);
end

function postsetFunctionStr = resolvePostsetFunction(propName, prop, typeName, namespace)

    hookInfo = file.getPropertyHooks(propName, prop, typeName, namespace);
    postsetStatements = hookInfo.PostsetStatements;

    if isa(prop, 'file.Attribute')

        if ~isempty(prop.dependent) && ~prop.readonly
    
            if ~isempty(prop.dependent_fullname)
                parentname = prop.dependent_fullname;
            else           
                parentname = prop.dependent;
            end
    
            conditionStr = sprintf(...
                'if isempty(obj.%s) && ~isempty(obj.%s)', ...
                parentname, propName);

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
    postsetLines = {sprintf('function postset_%s(obj)', propName), ...
        file.addSpaces(postsetBody, 4), ...
        'end'};
    postsetFunctionStr = strjoin(postsetLines, newline);
end
