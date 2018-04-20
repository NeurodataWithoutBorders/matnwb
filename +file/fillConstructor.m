function fcstr = fillConstructor(name, parentname, defaults, dependent, required, optional, props)
caps = upper(name);
fcnbody = strjoin({['% ' caps ' Constructor for ' name]...
    ['%     obj = ' caps '(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)']...
    }, newline);
fcns = {...
    @()fillParamDocs('REQUIRED', setdiff(required, dependent), props.named)...
    @()fillParamDocs('OPTIONAL', setdiff(optional, dependent), props.named)...
    @()fillBody(parentname, defaults, dependent, required, optional, props)...
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
    fdfp = 'containers.Map';
else
    fdfp = prop.type;
end
if nargin >= 2
    fdfp = ['% ' propnm ' = ' fdfp];
end
end

function fcstr = fillParamDocs(proptypenm, names, props)
fcstr = '';
if isempty(names)
    return;
end

if ~isempty(proptypenm)
    fcstr = ['% ' proptypenm];
end

for i=1:length(names)
    nm = names{i};
    prop = props(nm);
    fcstr = [fcstr newline fillDocFromProp(prop, nm)];
end
end

function bodystr = fillBody(pname, defaults, dependent, required, optional, props)
if isempty(defaults)
    bodystr = '';
else
    usmap = containers.Map;
    for i=1:length(defaults)
        nm = defaults{i};
        usmap(nm) = props.named(nm).value;
    end
    kwargs = io.map2kwargs(usmap);
    bodystr = ['varargin = [' util.cellPrettyPrint(kwargs) ' varargin];' newline];
end
bodystr = [bodystr 'obj = obj@' pname '(varargin{:});'];
bodystr = strjoin({bodystr...
    'p = inputParser;'...
    'p.KeepUnmatched = true;'... %suppress subclass/parent props
    'p.PartialMatching = false;'...
    'p.StructExpand = false;'}, newline);
params = [required optional];
for i=1:length(params)
    var = params{i};
    bodystr = [bodystr newline 'addParameter(p, ''' var ''', []);'];
end

bodystr = [bodystr newline 'parse(p, varargin{:});'];

%check required values that don't have a set value and are independent
req_unset = setdiff(required, [defaults dependent]);
if ~isempty(req_unset)
    req_body = strjoin({...
        ['required = ' util.cellPrettyPrint(req_unset) ';']...
        'missing = intersect(p.UsingDefaults, required);'...
        'if ~isempty(missing)'...
        '    error(''Missing Required Argument(s) { %s }'', strjoin(missing, '', ''));'...
        'end'}, newline);
    bodystr = [bodystr newline req_body];
end

%construct parent->dependent structure
dep_parents = struct();
for i=1:length(dependent)
    dep = dependent{i};
    dep_p = props.named(dep);
    parent = dep_p.dependent;
    if ~startsWith(dep, parent)
        parent = strrep(dep, ['_' dep_p.name], '');
    end
    if isfield(dep_parents, parent)
        deps = dep_parents.(parent);
        dep_parents.(parent) = [deps {dep}];
    else
        dep_parents.(parent) = {dep};
    end
end

%check each optional parent if they exist, then check their required dependents
dep_p_list = fieldnames(dep_parents);
for i=1:length(dep_p_list)
    parent = dep_p_list{i};
    children = util.cellPrettyPrint(dep_parents.(parent));
    bodystr = [bodystr newline 'types.util.checkDependent(''' parent ''', ' children ', p.UsingDefaults);'];
end

for i=1:length(params)
    var = params{i};
    bodystr = [bodystr newline 'obj.' var ' = p.Results.' var ';'];
end
end