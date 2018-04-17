function fcstr = fillConstructor(name, namespacename, parentname, req_names, opt_names, props)
caps = upper(name);
fcnbody = strjoin({...
    ['% ' caps ' Constructor for ' name]...
    ['%     obj = ' caps '(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)']...
    fillParamDocs('REQUIRED', req_names, props.named)...
    fillParamDocs('OPTIONAL', opt_names, props.named)...
    fillSetDocs(props.varargs, namespacename)...
    fillBody(parentname, req_names, opt_names, props.varargs)...
    }, newline);
fcstr = strjoin({...
    ['function obj = ' name '(varargin)']...
    file.addSpaces(fcnbody, 4)...
    'end'}, newline);
end

function fcstr = fillSetDocs(varprops, namespace)
fcstr = '';
for i=1:length(varprops)
    nm = varprops{i}.type;
    fcstr = [fcstr '%  ' nm ' = list of types.' namespace '.' nm newline];
end
end

function fdfp = fillDocFromProp(prop, propnm, spaces)
if ischar(prop)
    fdfp = prop;
elseif isstruct(prop)
    fnm = fieldnames(prop);
    subp = ['table with values:' newline];
    if nargin >= 3
        spc = spaces;
    else
        spc = 0;
    end
    
    for i=1:length(fnm)
        nm = fnm{i};
        subp = [subp fillDocFromProp(prop.(nm), nm, 4) newline];
    end
    fdfp = ['table with values:' newline file.addSpaces(subp, spc)];
elseif isa(prop, 'file.Attribute')
    fdfp = prop.dtype;
elseif isa(prop, 'java.util.HashMap')
    fdfp = ['ref to ' prop.get('target_type')];
elseif isa(prop, 'file.Dataset') && isempty(prop.type)
    fdfp = fillDocFromProp(prop.dtype);
elseif isempty(prop.type)
    fdfp = 'struct';
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
    fcstr = ['% ' proptypenm newline];
end
for i=1:length(names)
    nm = names{i};
    prop = props(nm);
    fcstr = [fcstr fillDocFromProp(prop, nm) newline];
end

end

function bodystr = fillBody(pname, req_vars, opt_vars, varargs)
bodystr = strjoin({...
    ['obj = obj@' pname '(varargin{:});']...
    'p = inputParser;'...
    'p.KeepUnmatched = true;'... %suppress subclass/parent props
    'p.PartialMatching = false;'...
    'p.StructExpand = false;'}, newline);
all_vars = [req_vars opt_vars];
for i=1:length(all_vars)
    var = all_vars{i};
    bodystr = [bodystr newline 'addParameter(p, ''' var ''', []);'];
end
req_vars_str = '';
for i=1:length(req_vars)
    req_vars_str = [req_vars_str ' ''' req_vars{i} ''''];
end
req_vars_str = strtrim(req_vars_str);
req_body = strjoin({...
    'parse(p, varargin{:});'...
    ['required = { ' req_vars_str ' };']...
    'missing = intersect(p.UsingDefaults, required);'...
    'if ~isempty(missing)'...
    '    error(''Missing Required Argument(s) { %s }'', strjoin(missing, '', ''));'...
    'end'}, newline);
bodystr = [bodystr newline req_body];
for i=1:length(all_vars)
    var = all_vars{i};
    bodystr = [bodystr newline 'obj.' var ' = p.Results.' var ';'];
end
%assign variable args should they exist
if ~isempty(varargs)
    setconst_str = '';
    for i=1:length(varargs)
        setconst_str = [setconst_str ' ''' varargs{i}.type ''''];
    end
    dynbody = strjoin({...
        ['obj.dynamic_constraints = [obj.dynamic_constraints {' setconst_str '}];']...
        'unmatchednames = fieldnames(p.Unmatched);'...
        'for i=1:length(unmatchednames)'...
        '    nm = unmatchednames{i};'...
        '    unmatched = p.Unmatched.(nm);'...
        '    obj.addDynamicProperty(nm, unmatched);'...
        'end'}, newline);
    bodystr = [bodystr newline dynbody];
end
end