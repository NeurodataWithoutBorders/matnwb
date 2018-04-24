function fcstr = fillConstructor(name, parentname, defaults, propnames, props, namespace)
caps = upper(name);
fcnbody = strjoin({['% ' caps ' Constructor for ' name]...
    ['%     obj = ' caps '(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)']...
    }, newline);
fcns = {...
    @()fillParamDocs(propnames, props)...
    @()fillBody(parentname, defaults, propnames, props, namespace)...
    };
for i=1:length(fcns)
    fcn = fcns{i};
    txt = fcn();
    if ~isempty(txt)
        fcnbody = [fcnbody newline txt];
    end
end
fcstr = strjoin({...
    ['function obj = ' name '(varargin)']...
    file.addSpaces(fcnbody, 4)...
    'end'}, newline);
end

function fdfp = fillDocFromProp(prop, propnm)
if ischar(prop)
    fdfp = prop;
elseif isstruct(prop)
    fnm = fieldnames(prop);
    subp = '';
    for i=1:length(fnm)
        nm = fnm{i};
        subpropl = file.addSpaces(fillDocFromProp(prop.(nm), nm), 4);
        subp = [subp newline subpropl];
    end
    fdfp = ['table with values:' newline subp];
elseif isa(prop, 'file.Attribute')
    fdfp = prop.dtype;
elseif isa(prop, 'java.util.HashMap')
    switch prop.get('reftype')
        case 'region'
            reftypenm = 'region';
        case 'object'
            reftypenm = 'object';
        otherwise
            error('Invalid reftype found whilst filling Constructor prop docs.');
    end
    fdfp = ['ref to ' prop.get('target_type') ' ' reftypenm];
elseif isa(prop, 'file.Dataset') && isempty(prop.type)
    fdfp = fillDocFromProp(prop.dtype);
elseif isempty(prop.type)
    fdfp = 'types.untyped.Set';
else
    fdfp = prop.type;
end
if nargin >= 2
    fdfp = ['% ' propnm ' = ' fdfp];
end
end

function fcstr = fillParamDocs(names, props)
fcstr = '';
if isempty(names)
    return;
end

for i=1:length(names)
    nm = names{i};
    prop = props(nm);
    fcstr = [fcstr newline fillDocFromProp(prop, nm)];
end
end

function bodystr = fillBody(pname, defaults, names, props, namespace)
if isempty(defaults)
    bodystr = '';
else
    usmap = containers.Map;
    for i=1:length(defaults)
        nm = defaults{i};
        usmap(nm) = props(nm).value;
    end
    kwargs = io.map2kwargs(usmap);
    bodystr = ['varargin = [' util.cellPrettyPrint(kwargs) ' varargin];' newline];
end
bodystr = [bodystr 'obj = obj@' pname '(varargin{:});'];

constrained = {};
parseable = {};
for i=1:length(names)
    var = names{i};
    pv = props(var);
    if ((isa(pv, 'file.Group') || isa(pv, 'file.Dataset')) && pv.isConstrainedSet)
        constrained = [constrained {var}];
    else
        parseable = [parseable {var}];
    end
end
if ~isempty(parseable)
    bodystr = strjoin({bodystr...
        'p = inputParser;'...
        'p.KeepUnmatched = true;'... %suppress subclass/parent props
        'p.PartialMatching = false;'...
        'p.StructExpand = false;'}, newline);
    for i=1:length(parseable)
        var = parseable{i};
        bodystr = [bodystr newline 'addParameter(p, ''' var ''', []);'];
    end
    
    bodystr = [bodystr newline 'parse(p, varargin{:});'];
    
    for i=1:length(parseable)
        var = parseable{i};
        bodystr = [bodystr newline 'obj.' var ' = p.Results.' var ';'];
    end
end

%if constrained sets exist, then check for nonstandard parameters and add as
%container.map
for i=1:length(constrained)
    cname = constrained{i};
    pc = props(cname);
    varname = lower(pc.type);
    pc_namespace = namespace.getNamespace(pc.type);
    if isempty(pc_namespace)
        warning('`%s`''s constructor is unable to check for type `%s` because its namespace could not be found.  Please generate the namespace or class definition for type `%s`.'...
            , pname, pc.type, pc.type);
        continue;
    end
    fulltypename = ['types.' pc_namespace.name '.' pc.type];
    methodcall = ['types.util.parseConstrained(''' fulltypename ''', varargin{:})'];
    bodystr = [bodystr newline 'obj.' varname ' = ' methodcall ';']; 
end
end