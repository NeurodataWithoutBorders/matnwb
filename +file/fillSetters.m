function fsstr = fillSetters(propnames, classprops)
fsstr = cell(size(propnames));
for i=1:length(propnames)
    nm = propnames{i};
    prop = classprops(nm);
    postsetFunctionStr = resolvePostsetFunction(nm, prop);
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

function postsetFunctionStr = resolvePostsetFunction(propname, prop)

    postsetFunctionStr = '';

    if isa(prop, 'file.Attribute')

        if ~isempty(prop.dependent) && ~prop.readonly
    
            if ~isempty(prop.dependent_fullname)
                parentname = prop.dependent_fullname;
            else           
                parentname = prop.dependent;
            end
    
            conditionStr = sprintf(...
                'if isempty(obj.%s) && ~isempty(obj.%s)', ...
                parentname, propname);

            warnIfDependencyMissingString = sprintf(...
                'obj.warnIfAttributeDependencyMissing(''%s'', ''%s'')', ...
                propname, parentname);

            syncTypedDatasetAttributeString = '';
            if prop.dependent_typed
                syncTypedDatasetAttributeString = sprintf([ ...
                    'if ~isempty(obj.%1$s) && isobject(obj.%1$s) && isprop(obj.%1$s, ''%2$s'')\n' ...
                    '    obj.%1$s.%2$s = obj.%3$s;\n' ...
                    'end'], parentname, prop.name, propname);
            end
    
            postsetLines = {...
                sprintf('function postset_%s(obj)', propname), ...
                file.addSpaces(conditionStr, 4), ...
                file.addSpaces(warnIfDependencyMissingString, 8), ...
                file.addSpaces('end', 4), ...
                'end'};
            if ~isempty(syncTypedDatasetAttributeString)
                postsetLines = [postsetLines(1:end-1), {file.addSpaces(syncTypedDatasetAttributeString, 4)}, postsetLines(end)];
            end
            postsetFunctionStr = strjoin(postsetLines, newline);
        end
    end
end
