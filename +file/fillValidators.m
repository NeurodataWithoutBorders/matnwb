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
            if isempty(ds.type)
                type = ds.dtype;
            else
                ds_namespace = namespacereg.getNamespace(ds.type).name;
                type = ['types.' ds_namespace '.' ds.type];
            end
            
            if isempty(ds.name)
                constr = [constr {type}];
            else
                namedprops.(ds.name) = type;
            end
        end
        
        for i=1:length(prop.subgroups)
            sg = prop.subgroups(i);
            sg_namespace = namespacereg.getNamespace(sg.type).name;
            sgfullname = ['types.' sg_namespace '.' sg.type];
            if isempty(sg.name)
                constr = [constr {sgfullname}];
            else
                namedprops.(sg.name) = sgfullname;
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
    namespace = namespacereg.getNamespace(prop.type).name;
    fuvstr = fillDtypeValidation(name, ['types.' namespace '.' prop.type], namespacereg);
end
end

function fdvstr = fillDimensionValidation(type, shape)
if strcmp(type, 'any') || strcmp(type, 'char')
    fdvstr = '';
    return;
end

validshapetokens = cell(size(shape));
for i=1:length(shape)
    %when there is more than one possible shape, the cells are nested
    if iscell(shape{i})
       shp = shape{i}{1}; 
    else
       shp = shape{i};
    end
    validshapetokens{i} = ['[' strtrim(evalc('disp(shp)')) ']'];
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
        ['    error(''Property `' name '` must be a table.'');']...
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
        ts = ['types.' namespacereg.getNamespace(tt).name '.' tt];
    elseif strcmp(type, 'any')
        fdvstr = '';
        return;
    else
        ts = type;
    end
    fdvstr = ['types.util.checkDtype(''' name ''', ''' ts ''', val);'];
end
end