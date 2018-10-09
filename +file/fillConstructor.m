function fcstr = fillConstructor(name, parentname, defaults, propnames, props, namespace)
caps = upper(name);
fcnbody = strjoin({['% ' caps ' Constructor for ' name] ...
    ['%     obj = ' caps '(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)'] ...
    }, newline);

txt = fillParamDocs(propnames, props);
if ~isempty(txt)
    fcnbody = [fcnbody newline txt];
end

txt = fillBody(parentname, defaults, propnames, props, namespace);
if ~isempty(txt)
    fcnbody = [fcnbody newline txt];
end

fcnbody = strjoin({fcnbody,...
    ['if endsWith(class(obj), ''', namespace.name, '.', name, ''')'],...
    '    types.util.checkUnset(obj, unique(varargin(1:2:end)));',...
    'end'}, newline);
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
    fdfp = ['table/struct of vectors/struct array/containers.Map of vectors with values:' newline subp];
elseif isa(prop, 'file.Attribute')
    fdfp = prop.dtype;
    if isa(fdfp, 'java.util.HashMap')
        switch fdfp.get('reftype')
            case 'region'
                reftypenm = 'region';
            case 'object'
                reftypenm = 'object';
            otherwise
                error('Invalid reftype found whilst filling Constructor prop docs.');
        end
        fdfp = ['ref to ' fdfp.get('target_type') ' ' reftypenm];
    end
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

fcstrlist = cell(length(names), 1);
for i=1:length(names)
    nm = names{i};
    prop = props(nm);
    fcstrlist{i} = fillDocFromProp(prop, nm);
end
fcstr = strjoin(fcstrlist, newline);
end

function bodystr = fillBody(pname, defaults, names, props, namespace)
if isempty(defaults)
    bodystr = '';
else
    usmap = containers.Map;
    for i=1:length(defaults)
        nm = defaults{i};
        if strcmp(props(nm).dtype, 'char')
            usmap(nm) = ['''' props(nm).value ''''];
        else
            usmap(nm) = [props(nm).dtype '(' props(nm).value ')'];
        end
    end
    kwargs = io.map2kwargs(usmap);
    bodystr = ['varargin = [{' misc.cellPrettyPrint(kwargs) '} varargin];' newline];
end
bodystr = [bodystr 'obj = obj@' pname '(varargin{:});'];

if isempty(names)
    return;
end

bodystr = strjoin({bodystr...
    'p = inputParser;'...
    'p.KeepUnmatched = true;'... %suppress subclass/parent props
    'p.PartialMatching = false;'...
    'p.StructExpand = false;'}, newline);

constrained = false(size(names));
anon = false(size(names));
for i=1:length(names)
    nm = names{i};
    prop = props(nm);
    if ((isa(prop, 'file.Group') &&...
            (prop.isConstrainedSet || prop.hasAnonData || prop.hasAnonGroups))...
            || (isa(prop, 'file.Dataset') && prop.isConstrainedSet))
        def = 'types.untyped.Set()';
        constrained(i) = prop.isConstrainedSet;
    else
        anon(i) = (isa(prop, 'file.Group') || isa(prop, 'file.Dataset'))...
            && isempty(prop.name);
        def = '[]';
    end
    s = [newline 'addParameter(p, ''' nm ''', ' def ');'];
    bodystr(end+1:end+length(s)) = s;
end
bodystr = [bodystr newline 'parse(p, varargin{:});'];

named = names(~(constrained | anon));
s = strcat('obj.', named, ' = p.Results.', named, ';');
s = strjoin(s, newline);
bodystr(end+1:end+length(s)+1) = [newline s];

%if constrained/anon sets exist, then check for nonstandard parameters and add as
%container.map
constrainedNames = names(constrained);
for i=1:length(constrainedNames)
    type = props(constrainedNames{i}).type;
    varname = lower(type);
    pc_namespace = namespace.getNamespace(type);
    if isempty(pc_namespace)
        warning(['`%s`''s constructor is unable to check for type `%s` ' ...
            'because its namespace could not be found.  Please generate ' ...
            'the namespace or class definition for type `%s`.']...
            , pname, type, type);
        continue;
    end
    fulltypename = ['types.' pc_namespace.name '.' type];
    methodcall = ['types.util.parseConstrained(''' pname ''', ''' fulltypename ''', varargin{:})'];
    s = [newline 'obj.' varname ' = ' methodcall ';'];
    bodystr(end+1:end+length(s)) = s;
end

%if anonymous values exist, then check for nonstandard parameters and add
%as Anon
anonNames = names(anon);
for i=1:length(anonNames)
    type = props(anonNames{i}).type;
    varname = lower(type);
    pc_namespace = namespace.getNamespace(type);
    if isempty(pc_namespace)
        warning(['`%s`''s constructor is unable to check for type `%s` ' ...
            'because its namespace could not be found.  Please generate ' ...
            'the namespace or class definition for type `%s`.']...
            , pname, type, type);
        continue;
    end
    fulltypename = ['types.' pc_namespace.name '.' type];
    methodcall = ['types.util.parseAnon(''' fulltypename ''', varargin{:})'];
    s = [newline 'obj.' varname ' = ' methodcall ';'];
    bodystr(end+1:end+length(s)) = s;
end
end