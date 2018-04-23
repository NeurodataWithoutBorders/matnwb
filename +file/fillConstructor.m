function fcstr = fillConstructor(name, parentname, defaults, propnames, props)
caps = upper(name);
fcnbody = strjoin({['% ' caps ' Constructor for ' name]...
    ['%     obj = ' caps '(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)']...
    }, newline);
fcns = {...
    @()fillParamDocs(propnames, props)...
    @()fillBody(parentname, defaults, propnames, props)...
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

function bodystr = fillBody(pname, defaults, names, props)
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
bodystr = strjoin({bodystr...
    'p = inputParser;'...
    'p.KeepUnmatched = true;'... %suppress subclass/parent props
    'p.PartialMatching = false;'...
    'p.StructExpand = false;'}, newline);
for i=1:length(names)
    var = names{i};
    bodystr = [bodystr newline 'addParameter(p, ''' var ''', []);'];
end

bodystr = [bodystr newline 'parse(p, varargin{:});'];

for i=1:length(names)
    var = names{i};
    bodystr = [bodystr newline 'obj.' var ' = p.Results.' var ';'];
end
end