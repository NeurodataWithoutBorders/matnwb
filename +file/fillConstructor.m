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

function bodystr = fillBody(pname, propwithvals, req_vars, opt_vars, props)
all_vars = [req_vars opt_vars];

upstream = {}; %kwargs to be sent to parent
hardcoded = {}; %hardcoded defaults that should be instantiated now.
for i=1:length(propwithvals)
    pnm = propwithvals{i};
    prop = props.named(pnm);
    if any(strcmp(all_vars, pnm)) %that is, it's noninherited
        [~, status] = str2num(prop.value);
        if status
            wrapped_assgn = prop.value;
        else
            wrapped_assgn = ['''' prop.value ''''];
        end
        
        hardcoded = [hardcoded {['obj.' pnm ' = ' wrapped_assgn ';']}];
    else
        upstream = [upstream {pnm} {prop.value}];
    end
end
if isempty(upstream)
    bodystr = '';
else
    bodystr = ['varargin = [' util.cellPrettyPrint(upstream) ' varargin];' newline];
end
bodystr = [bodystr 'obj = obj@' pname '(varargin{:});'];

if ~isempty(hardcoded)
    bodystr = [bodystr newline strjoin(hardcoded, newline)];
end
bodystr = strjoin({bodystr...
    'p = inputParser;'...
    'p.KeepUnmatched = true;'... %suppress subclass/parent props
    'p.PartialMatching = false;'...
    'p.StructExpand = false;'}, newline);

for i=1:length(all_vars)
    var = all_vars{i};
    bodystr = [bodystr newline 'addParameter(p, ''' var ''', []);'];
end
req_empty_vars = setdiff(req_vars, propwithvals); %check required values that don't have a set value
req_vars_str = util.cellPrettyPrint(req_empty_vars);
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