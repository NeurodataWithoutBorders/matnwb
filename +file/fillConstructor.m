function fcstr = fillConstructor(name, namespace, parent, ro_names, req_names, opt_names, props)
caps = upper(name);
all_req_names = [ro_names req_names];
fcstr = ['function obj = ' name '(varargin)' newline...
    '% ' caps ' Constructor for ' name newline...
    '%     obj = ' caps '(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)' newline...
    fillParamDocs('REQUIRED', all_req_names, props.properties)...
    fillParamDocs('OPTIONAL', opt_names, props.properties)...
    fillSetDocs(props.varargs, namespace)...
    fillBody(parent, all_req_names, opt_names, props.varargs)...
    'end' newline];
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
    subp = ['struct with values:' newline];
    if nargin >= 3
        spc = spaces;
    else
        spc = 0;
    end
    
    for i=1:length(fnm)
        subp = [subp fillDocFromProp(prop.(fnm), fnm, 4) newline];
    end
    fdfp = ['struct with values:' newline file.addSpaces(subp, spc)];
elseif isa(prop, 'file.Attribute')
    fdfp = prop.dtype;
elseif isa(prop, 'java.util.HashMap')
    fdfp = ['ref to ' prop.get('target_type')];
elseif isa(prop, 'file.Dataset') && ~prop.isClass
    fdfp = fillDocFromProp(prop.dtype);
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
bodystr = [...
    'obj = obj@' pname '(varargin{:});' newline...
    'p = inputParser;' newline...
    'p.KeepUnmatched = true;' newline... %suppress subclass/parent props
    'p.PartialMatching = false;' newline...
    'p.StructExpand = false;' newline];
all_vars = [req_vars opt_vars];
for i=1:length(all_vars)
    var = all_vars{i};
    bodystr = [bodystr 'addParameter(p, ''' var ''', []);' newline];
end
req_vars_list = cell(size(req_vars));
for i=1:length(req_vars)
    req_vars_list{i} = ['''' req_vars{i} ''''];
end
req_vars_list = strjoin(req_vars_list, ' ');
bodystr = [bodystr ...
    'parse(p, varargin{:});' newline...
    'required = {' req_vars_list '};' newline...
    'missing = intersect(p.UsingDefaults, required);' newline...
    'if ~isempty(missing)' newline...
    '    error(''Missing Required Argument(s) { %s }'', strjoin(missing, '', '');' newline...
    'end' newline];
for i=1:length(all_vars)
    var = all_vars{i};
    bodystr = [bodystr 'obj.' var ' = p.Results.' var ';' newline];
end
%assign variable args should they exist
if ~isempty(varargs)
    setconst = cell(size(varargs));
    for i=1:length(varargs)
        setconst{i} = ['''' varargs{i}.type ''''];
    end
    setconst = strjoin(setconst, ' ');
    bodystr = [bodystr...
        'setconstraints = {' setconst '};' newline...
        'unmatchednames = fieldnames(p.Unmatched);' newline...
        'for i=1:length(unmatchednames)' newline...
        '    nm = unmatchednames{i};' newline...
        '    unmatched = p.Unmatched.(nm);' newline...
        '    for j=1:length(setconstraints)' newline...
        '        setconst = setconstraints{j};' newline...
        '        try' newline...
        '            feval([''obj.validate_dynamic_'' setconst], unmatched);' newline...
        '        catch' newline...
        '            continue;' newline...
        '        end' newline...
        '        newprop = addprop(obj, nm);' newline...
        '        newprop.SetMethod = str2func([''obj.set_dynamic_'' setconst]);' newline... %TODO
        '        obj.(nm) = unmatched;' newline...
        '    end' newline...
        'end' newline];
end
end