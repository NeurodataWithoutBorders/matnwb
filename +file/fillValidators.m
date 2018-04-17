function fvstr = fillValidators(propnames, props, namespacereg)
fvstr = '';
for i=1:length(propnames)
    nm = propnames{i};
    prop = props.named(nm);
    
    if startsWith(class(prop), 'file.')
        validationBody = fillUnitValidation(nm, prop, namespacereg);
    else %primitive type
        validationBody = fillDtypeValidation(nm, prop, namespacereg);
    end
    hdrstr = ['function validate_' nm '(obj, val)'];
    fcnStr = strjoin({hdrstr file.addSpaces(validationBody, 4) 'end'}, newline);
    fvstr = [fvstr newline fcnStr];
end
end

function fuvstr = fillUnitValidation(name, prop, namespacereg)
fuvstr = '';
if isa(prop, 'file.Dataset')
    if isempty(prop.type)
        fuvstr = strjoin({fuvstr...
            fillDtypeValidation(name, prop.dtype, namespacereg)...
            fillDimensionValidation(prop.dtype, prop.shape)...
            }, newline);
    else
        namespace = namespacereg.getNamespace(prop.type).name;
        fullclassname = ['types.' namespace '.' prop.type];
        fuvstr = [fuvstr newline fillDtypeValidation(name, fullclassname, namespacereg)];
    end
elseif isa(prop, 'file.Group')
    if isempty(prop.type)
        namedprops = struct();
        constr = {};
        for i=1:length(prop.datasets)
            ds = prop.datasets(i);
            if isempty(ds.name)
                if isempty(ds.type)
                    typespec = ds.dtype;
                else
                    typespec = ds.type;
                end
                constr = [constr {typespec}];
            elseif isempty(ds.type)
                namedprops.(ds.name) = ds.dtype;
            else
                namedprops.(ds.name) = ds.type;
            end
        end
        
        for i=1:length(prop.subgroups)
            sg = prop.subgroups(i);
            if isempty(sg.name)
                constr = [constr sg.type];
            else
                namedprops.(sg.name) = sg.type;
            end
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
            ['types.util.checkConstrained(''' name ''', namedprops, constrained, val);']...
            }, newline);
    else
        namespace = namespacereg.getNamespace(prop.type).name;
        fulltypename = ['types.' namespace '.' prop.type];
        fuvstr = fillDtypeValidation(name, fulltypename, namespacereg);
    end
elseif isa(prop, 'file.Attribute')
    fuvstr = fillDtypeValidation(name, prop.dtype, namespacereg);
else %Link
    fuvstr = fillDtypeValidation(name, prop.type, namespacereg);
end
end

function fdvstr = fillDimensionValidation(type, shape)
if strcmp(type, 'any') || strcmp(type, 'char')
    fdvstr = '';
    return;
end

validshapetokens = cell(size(shape));
for i=1:length(shape)
    validshapetokens{i} = ['[' strtrim(evalc('disp(shape{i})')) ']'];
end
fdvstr = strjoin({...
    'valsz = size(val);'...
    ['validshapes = {' strjoin(validshapetokens, ' ') '};']...
    'types.util.checkDims(valsz, validshapes);'}, newline);
end

%NOTE: can return empty strings
function fdvstr = fillDtypeValidation(name, type, namespacereg)
if isstruct(type)
    fnames = fieldnames(type);
    fdvstr = strjoin({...
        'if ~istable(val)'...
        '    error(''Property `' name '` must be a table.'');'...
        'end'...
        }, newline);
    for i=1:length(fnames)
        nm = fnames{i};
        subtypecheck = fillDtypeValidation([name '.' nm], type.(nm), namespacereg);
        if ~isempty(subtypecheck)
            fdvstr = [fdvstr newline strrep(subtypecheck, 'val', ['val.' nm])];
        end
    end
else
    if isa(type, 'java.util.HashMap')
        %ref
        tt = type.get('target_type');
        ts = namespacereg.getNamespace(tt).name;
    elseif strcmp(type, 'any')
        fdvstr = '';
        return;
    else
        ts = type;
    end
    fdvstr = ['types.util.checkDtype(''' name ''', ''' ts ''', val);'];
    
    % special case for region reftype
    if strcmp(name, 'region') && strcmp(type, 'double')
        fdvstr = [fdvstr newline 'types.util.checkRegion(obj, val);'];
    end
end
end