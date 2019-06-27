function fvstr = fillValidators(propnames, props, namespacereg)
fvstr = '';
for i=1:length(propnames)
    nm = propnames{i};
    prop = props(nm);
    
    %if readonly and value exists then ignore
    if isa(prop, 'file.Attribute') && prop.readonly && ~isempty(prop.value)
        continue;
    end
    if startsWith(class(prop), 'file.')
        validationBody = fillUnitValidation(nm, prop, namespacereg);
    else %primitive type
        validationBody = fillDtypeValidation(nm, prop);
    end
    hdrstr = ['function val = validate_' nm '(obj, val)'];
    if isempty(validationBody)
        fcnStr = [hdrstr newline 'end'];
    else
        fcnStr = strjoin({hdrstr ...
            file.addSpaces(strtrim(validationBody), 4) 'end'}, newline);
    end
    fvstr = [fvstr newline fcnStr];
end
end

function fuvstr = fillUnitValidation(name, prop, namespacereg)
fuvstr = '';
constr = {};
if isa(prop, 'file.Dataset')
    if isempty(prop.type)
        fuvstr = strjoin({fuvstr...
            fillDtypeValidation(name, prop.dtype)...
            fillDimensionValidation(prop.dtype, prop.shape)...
            }, newline);
    elseif prop.isConstrainedSet
        namespace = namespacereg.getNamespace(prop.type);
        if isempty(namespace)
            warning(['Namespace could not be found for type `%s`.' ...
                '  Skipping Validation for property `%s`.'], prop.type, name);
            return;
        end
        fullname = ['types.' namespace.name '.' prop.type ];
        fuvstr = strjoin({fuvstr...
            ['constrained = { ''' fullname ''' };']...
            ['types.util.checkSet(''' name ''', struct(), constrained, val);']...
            }, newline);
    else
        namespace = namespacereg.getNamespace(prop.type);
        if isempty(namespace)
            warning(['Namespace could not be found for type `%s`.' ...
                '  Skipping Validation for property `%s`.'], prop.type, name);
            return;
        end
        fullclassname = ['types.' namespace.name '.' prop.type];
        fuvstr = [fuvstr newline ...
            fillDtypeValidation(name, fullclassname)];
    end
elseif isa(prop, 'file.Group')
    if isempty(prop.type)
        namedprops = struct();
        
        %process datasets
        %if type, check if constrained
        % if constrained, add to constr
        % otherwise, check type once
        %otherwise, check dtype
        for i=1:length(prop.datasets)
            ds = prop.datasets(i);
            
            if isempty(ds.type)
                namedprops.(ds.name) = ds.dtype;
            else
                ds_nmspc = namespacereg.getNamespace(ds.type).name;
                type = ['types.' ds_nmspc '.' ds.type];
                if ds.isConstrainedSet
                    constr = [constr {type}];
                else
                    namedprops.(ds.name) = type;
                end
            end
        end
        
        %process groups
        %if type, check if constrained
        % if constrained, add to constr
        % otherwise, check type once
        %otherwise, error.  This shouldn't happen.
        for i=1:length(prop.subgroups)
            sg = prop.subgroups(i);
            sg_namespace = namespacereg.getNamespace(sg.type).name;
            sgfullname = ['types.' sg_namespace '.' sg.type];
            if isempty(sg.type)
                error('Weird case with two untyped groups');
            end
            
            if isempty(sg.name)
                constr = [constr {sgfullname}];
            else
                namedprops.(sg.name) = sgfullname;
            end
        end
        
        %process attributes
        if ~isempty(prop.attributes)
            namedprops = [namedprops;...
                containers.Map({prop.attributes.name}, ...
                {prop.attributes.dtype})];
        end
        
        %process links
        if ~isempty(prop.links)
            linktypes = {prop.links.type};
            linkNamespaces = cell(size(linktypes));
            for i=1:length(linktypes)
                lt = linktypes{i};
                linkNamespaces{i} = namespacereg.getNamespace(lt);
            end
            linkTypenames = strcat('types.', linkNamespaces, '.', linktypes);
            namedprops = [namedprops; ...
                containers.Map({prop.links.name}, linkTypenames)];
        end
        
        propnames = fieldnames(namedprops);
        fuvstr = 'namedprops = struct();';
        for i=1:length(propnames)
            nm = propnames{i};
            fuvstr = strjoin({fuvstr...
                ['namedprops.' nm ' = ''' namedprops.(nm) ''';']}, newline);
        end
        fuvstr = strjoin({fuvstr...
            ['constrained = {' strtrim(evalc('disp(constr)')) '};']...
            ['types.util.checkSet(''' name ''', namedprops, constrained, val);']...
            }, newline);
    elseif prop.isConstrainedSet
        namespace = namespacereg.getNamespace(prop.type).name;
        fuvstr = strjoin({fuvstr...
            ['constrained = {''types.' namespace '.' prop.type '''};']...
            ['types.util.checkSet(''' name ''', struct(), constrained, val);']...
            }, newline);
    else
        namespace = namespacereg.getNamespace(prop.type).name;
        fulltypename = ['types.' namespace '.' prop.type];
        fuvstr = fillDtypeValidation(name, fulltypename);
    end
elseif isa(prop, 'file.Attribute')
    fuvstr = fillDtypeValidation(name, prop.dtype);
else %Link
    namespace = namespacereg.getNamespace(prop.type).name;
    fuvstr = fillDtypeValidation(name, ['types.' namespace '.' prop.type]);
end
end

function fdvstr = fillDimensionValidation(type, shape)
if strcmp(type, 'any') || strcmp(type, 'char')
    fdvstr = '';
    return;
end

shape = strcat('[', shape, ']');
if iscellstr(shape)
    shape = strjoin(shape, ', ');
end
shape = strcat('{', shape, '}');

fdvstr = strjoin({...
    'if isa(val, ''types.untyped.DataStub'')' ...
    '    valsz = val.dims;' ...
    'else' ...
    '    valsz = size(val);'...
    'end' ...
    ['validshapes = ' shape ';']...
    'types.util.checkDims(valsz, validshapes);'}, newline);
end

%NOTE: can return empty strings
function fdvstr = fillDtypeValidation(name, type)
if isstruct(type)
    fnames = fieldnames(type);
    fdvstr = strjoin({...
        'if isempty(val) || isa(val, ''types.untyped.DataStub'')'...
        '    return;'...
        'end'...
        'if ~istable(val) && ~isstruct(val) && ~isa(val, ''containers.Map'')'...
        ['    error(''Property `' name '` must be a table,struct, or containers.Map.'');']...
        'end'...
        'vprops = struct();'...
        }, newline);
    vprops = cell(length(fnames),1);
    for i=1:length(fnames)
        nm = fnames{i};
        if isa(type.(nm), 'java.util.HashMap')
            %ref
            switch type.(nm).get('reftype')
                case 'region'
                    rt = 'RegionView';
                case 'object'
                    rt = 'ObjectView';
            end
            typeval = ['types.untyped.' rt];
        else
            typeval = type.(nm);
        end
        vprops{i} = ['vprops.' nm ' = ''' typeval ''';'];
    end
    fdvstr = [fdvstr, newline, strjoin(vprops, newline), newline, ...
        'val = types.util.checkDtype(''' name ''', vprops, val);'];
else
    fdvstr = '';
    if isa(type, 'java.util.HashMap')
        %ref
        ref_t = type.get('reftype');
        switch ref_t
            case 'region'
                rt = 'RegionView';
            case 'object'
                rt = 'ObjectView';
        end
        ts = ['types.untyped.' rt];
        %there is no objective way to guarantee a reference refers to the
        %correct target type
        tt = type.get('target_type');
        fdvstr = ['% Reference to type `' tt '`' newline];
    elseif strcmp(type, 'any')
        fdvstr = '';
        return;
    else
        ts = type;
    end
    fdvstr = [fdvstr ...
        'val = types.util.checkDtype(''' name ''', ''' ts ''', val);'];
end
end