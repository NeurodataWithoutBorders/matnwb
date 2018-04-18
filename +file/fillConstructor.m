function fcstr = fillConstructor(name, namespacename, parentname, pwithval, req_names, opt_names, props)
caps = upper(name);
fcnbody = strjoin({['% ' caps ' Constructor for ' name]...
    ['%     obj = ' caps '(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)']...
    }, newline);
fcns = {...
    @() fillParamDocs('REQUIRED', req_names, props.named)...
    @() fillParamDocs('OPTIONAL', opt_names, props.named)...
    @() fillSetDocs(name, props.varargs, namespacename)...
    @() fillBody(parentname, pwithval, req_names, opt_names, props)...
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

function fcstr = fillSetDocs(name, varprops, namespace)
fcstr = '';
for i=1:length(varprops)
    nm = varprops{i}.type;
    if strcmp(nm, name)
        continue;
    end
    fcstr = [fcstr '%  ' nm ' = list of types.' namespace '.' nm newline];
end
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
    fdfp = ['ref to ' prop.get('target_type')];
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

function bodystr = fillBody(pname, propwithvals, req_vars, opt_vars, props)
bodystr = ['obj = obj@' pname '(varargin{:});'];

for i=1:length(propwithvals)
    pnm = propwithvals{i};
    prop = props.named(pnm);
    [~, status] = str2num(prop.value);
    if status
        wrapped_assgn = prop.value;
    else
        wrapped_assgn = ['''' prop.value ''''];
    end
    bodystr = [bodystr newline 'obj.' pnm ' = ' wrapped_assgn ';'];
end
bodystr = strjoin({bodystr...
    'p = inputParser;'...
    'p.KeepUnmatched = true;'... %suppress subclass/parent props
    'p.PartialMatching = false;'...
    'p.StructExpand = false;'}, newline);
all_vars = [req_vars opt_vars];
for i=1:length(all_vars)
    var = all_vars{i};
    bodystr = [bodystr newline 'addParameter(p, ''' var ''', []);'];
end

req_vars_str = util.cellPrettyPrint(req_vars);
req_body = strjoin({...
    'parse(p, varargin{:});'...
    ['required = ' req_vars_str ';']...
    'missing = intersect(p.UsingDefaults, required);'...
    'if ~isempty(missing)'...
    '    error(''Missing Required Argument(s) { %s }'', strjoin(missing, '', ''));'...
    'end'}, newline);
bodystr = [bodystr newline req_body];
for i=1:length(all_vars)
    var = all_vars{i};
    bodystr = [bodystr newline 'obj.' var ' = p.Results.' var ';'];
end
end