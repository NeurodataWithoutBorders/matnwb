function s = fillProps(props, names, varargin)
p = inputParser;
p.addParameter('PropertyAttributes', '', ...
    @(x)validateattributes(x, {'char'}, {'scalartext'}, 'fillProps', 'Attribute'));
p.parse(varargin{:});

proplines = cell(size(names));
for i=1:length(names)
    pnm = names{i};
    proplines{i} = [pnm '; % ' getPropStr(props(pnm))];
end

if isempty(p.Results.PropertyAttributes)
    options = '';
else
    options = ['(' p.Results.PropertyAttributes ')'];
end

if isempty(proplines)
    s = '';
else
    s = strjoin({...
        ['properties' options]...
        file.addSpaces(strjoin(proplines, newline), 4)...
        'end'}, newline);
end
end

function propStr = getPropStr(prop, propName)
if ischar(prop)
    typeStr = prop;
elseif isstruct(prop)
    columnNames = fieldnames(prop);
    columnDocStr = cell(size(columnNames));
    for i=1:length(columnNames)
        name = columnNames{i};
        columnDocStr{i} = getPropStr(prop.(name), name);
    end
    typeStr = ['Table with columns: (', strjoin(columnDocStr, ', '), ')'];
elseif isa(prop, 'file.Attribute')
    if isa(prop.dtype, 'containers.Map')
        switch prop.dtype('reftype')
            case 'region'
                refTypeName = 'Region';
            case 'object'
                refTypeName = 'Object';
            otherwise
                error('Invalid reftype found whilst filling Constructor prop docs.');
        end
        typeStr = sprintf('%s Reference to %s', refTypeName, prop.dtype('target_type'));
    else
        typeStr = prop.dtype;
    end
elseif isa(prop, 'containers.Map')
    switch prop('reftype')
        case 'region'
            refTypeName = 'region';
        case 'object'
            refTypeName = 'object';
        otherwise
            error('Invalid reftype found whilst filling Constructor prop docs.');
    end
    typeStr = sprintf('%s Reference to %s', refTypeName, prop('target_type'));
elseif isa(prop, 'file.Dataset') && isempty(prop.type)
    typeStr = getPropStr(prop.dtype);
elseif isempty(prop.type)
    typeStr = 'types.untyped.Set';
else
    typeStr = prop.type;
end

if isa(prop, 'file.Dataset') || isa(prop, 'file.Attribute') || isa(prop, 'file.Group')
    docStr = prop.doc;
else
    docStr = '';
end

propStr = sprintf('(%s) %s', typeStr, docStr);

if nargin >= 2
    propStr = [propName ' = ' propStr];
end
end