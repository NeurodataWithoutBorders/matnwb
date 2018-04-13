function fvstr = fillValidators(propnames, props, namespacereg)
fvstr = '';
for i=1:length(propnames)
    nm = propnames{i};
    prop = props.properties(nm);
    
    if startsWith(class(prop), 'file.')
        validationBody = fillUnitValidation(nm, prop, namespacereg);
    else %primitive type
        validationBody = fillDtypeValidation(nm, prop, {1}, namespacereg);
    end
    hdrstr = ['function validate_' nm '(obj, val)'];
    fcnStr = strjoin({hdrstr file.addSpaces(validationBody, 4) 'end'}, newline);
    fvstr = [fvstr newline fcnStr];
end
end

function fuvstr = fillUnitValidation(name, prop, namespacereg)
fuvstr = '';
if isa(prop, 'file.Dataset')
    if prop.linkable
        fuvstr = strjoin({...
            'if isa(val, ''types.untyped.Link'')'...
            '    return;'...%TODO LINK VALIDATION
            'end'
            }, newline);
    end
    
    if prop.isClass
        namespace = namespacereg.getNamespace(prop.type).name;
        fullclassname = ['types.' namespace '.' prop.type];
        fuvstr = [fuvstr newline fillClassValidation(fullclassname, prop.isConstrainedSet)];
    else
        fuvstr = strjoin({fuvstr...
            fillDtypeValidation(name, prop.dtype, prop.shape, namespacereg)...
            fillDimensionValidation(prop.dtype, prop.shape)...
            }, newline);
    end
elseif isa(prop, 'file.Group')
    namespace = namespacereg.getNamespace(prop.type).name;
    fulltypename = ['types.' namespace '.' prop.type];
    fuvstr = fillClassValidation(fulltypename, prop.isConstrainedSet);
elseif isa(prop, 'file.Attribute')
    fuvstr = fillDtypeValidation(name, prop.dtype, {1}, namespacereg);
else %Link
    namespace = namespacereg.getNamespace(prop.type).name;
    errmsg = ['error(''Property ' prop.name ' must be a reference to a types.' ...
        namespace '.' prop.type ''');'];
    fuvstr = strjoin({...
        ['if ~isa(val, ''' prop.type ''')']...
        ['    ' errmsg]...
        'end'}, newline);
end
end

function fdvstr = fillDimensionValidation(type, shape)
if strcmp(type, 'any') || (strcmp(type, 'char') && isempty(shape))
    fdvstr = '';
    return;
end

if strcmp(type, 'char')
    fdvstr = strjoin({...
        'if (iscellstr(val) && length(val) ~= 1) ||...'...
        '   (isstring(val) && length(val) ~= 1) ||...'...
        '   ~ischar(val)'...
        '    error(''val must be a vector char array, or a cellstring/string array of length 1'');'...
        'end'...
        }, newline);
else
    validshapetokens = cell(size(shape));
    for i=1:length(shape)
        validshapetokens{i} = ['[' strtrim(evalc('disp(shape{i})')) ']'];
    end
    fdvstr = strjoin({...
        'valsz = size(val);'...
        ['validshapes = {' strjoin(validshapetokens, ' ') '};']...
        'types.util.checkDims(valsz, validshapes);'}, newline);
end
end

function fcvstr = fillClassValidation(fulltypename, constrained)
if constrained
    errmsg = ['error(''The class (or superclass) of this property must be '...
        fulltypename ' or a cell array consisting of this class/superclass.'');'];
    cellerrmsg = [...
        'error(''All classes (or superclasses) in this cell array must be a '...
        fulltypename ''');'];
    fcvstr = strjoin({...
        ['if ~isa(val, ''' fulltypename ''') || ~iscell(val)']...
        ['    ' errmsg]...
        'end'...
        'if iscell(val)'...
        '    for i=1:length(val)'...
        ['        if ~isa(val{i}, ''' fulltypename ''')']...
        ['            ' cellerrmsg]...
        '        end'...
        '    end'...
        'end'}, newline);
else
    errmsg = ['error(''This property must be of type ' fulltypename ''');'];
    fcvstr = strjoin({...
        ['if ~isa(val, ''' fulltypename ''')']...
        ['    ' errmsg]...
        'end'}, newline);
end
end

%NOTE: can return empty strings
function fdvstr = fillDtypeValidation(name, type, shape, namespacereg)
if ~ischar(type) %this type is either compound or a reference
    if isstruct(type)
        %compound types are tables
        fnm = fieldnames(type);
        fnmstr = ['{' strtrim(evalc('disp(fnm)')) '}'];
        fdvstr = strjoin({...
            'if ~istable(val)'...
            ['    error(''Property ' name ' must be a table.'');']...
            'end'...
            ['allowedfnm = ' fnmstr ';']...
            'if ~isempty(intersect(allowedfnm, val.Properties.VariableNames))'...
            ['   error(''Property ' name ' must be a table with variables ' fnmstr '.'');']...
            'end'}, newline);
        for i=1:length(fnm)
            nm = fnm{i};
            subfill = fillDtypeValidation(nm, type.(nm), {inf}, namespacereg);
            %change references to val with the actual table property
            subfillrep = strrep(subfill, 'val', ['val.' nm]);
            fdvstr = strjoin({fdvstr subfillrep}, newline);
        end
    else
        %ref
        tt = type.get('target_type');
        ptt = namespacereg.getNamespace(tt).name;
        %handle object
        fdvstr = strjoin({...
            ['if ~isa(val, ''' tt ''')']...
            ['    error(''Property ' name ' must be a reference to a types.' ptt '.' tt ''');']...
            'end'}, newline);
    end
    return;
end

errmsg = ['error(''Property ' name ' must be a ' type '.'');'];
typechck = '';
switch type
    case 'any'
        fdvstr = '';
        return;
    case 'double'
        typechck = '~isnumeric(val)';
    case {'int64' 'uint64'}
        typechck = '~isinteger(val)';
        if strcmp(type, 'uint64')
            typechck = [typechck ' || val < 0'];
        end
    case 'char'
        dimsz = numel(shape{1});
        if dimsz == 1
            %regular char array
            typechck = '~ischar(val)';
        else
            %multidim cell array
            typechck = '~iscellstr(val)';
        end
end
fdvstr = strjoin({...
    ['if ' typechck]...
    ['    ' errmsg]...
    'end'}, newline);

% special case for region reftype
if strcmp(name, 'region') && strcmp(type, 'double')
    fdvstr = [fdvstr newline 'types.util.checkRegion(obj, val);'];
end
end