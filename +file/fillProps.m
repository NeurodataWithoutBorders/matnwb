function s = fillProps(props, names, varargin)
    % Fills the property list in the classdef
    assert(isa(props, 'containers.Map'));
    assert(iscellstr(names) || isstring(names));
    s = '';
    if isempty(names)
        return;
    end
    
    p = inputParser;
    p.addParameter('PropertyAttributes', '', ...
        @(x)validateattributes(x, {'char'}, {'scalartext'}, mfilename, 'Attribute'));
    p.addParameter('IsRequired', false, ...
        @(x)validateattributes(x, {'logical'}, {'scalar'}, mfilename, 'IsRequired'));
    p.parse(varargin{:});
    
    if p.Results.IsRequired
        requiredStr = 'REQUIRED';
    else
        requiredStr = '';
    end
    
    proplines = cell(size(names));
    for i=1:length(names)
        pnm = names{i};
        propInfo = props(pnm);
        propStr = strjoin(strsplit(getPropStr(props(pnm)), newline), [newline '% ']);
        defaultValue = [];
        if startsWith(class(propInfo), 'file.')
            if isprop(propInfo, 'value')
                defaultValue = propInfo.value;
            end
        end
        if isempty(defaultValue)
            proplines{i} = [pnm '; % ' requiredStr ' ' propStr];
        else
            defaultValue = formatValueAsString(defaultValue);
            proplines{i} = [pnm ' = %s; %% ', requiredStr ' ' propStr];
            proplines{i} = sprintf(proplines{i}, defaultValue);
        end
    end
    
    if isempty(p.Results.PropertyAttributes)
        options = '';
    else
        options = ['(' p.Results.PropertyAttributes ')'];
    end
    
    s = strjoin({...
        ['properties' options]...
        file.addSpaces(strjoin(proplines, newline), 4)...
        'end'}, newline);
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
            assertValidRefType(prop.dtype('reftype'))
            typeStr = sprintf('%s reference to %s', capitalize(prop.dtype('reftype')), prop.dtype('target_type'));
        else
            typeStr = prop.dtype;
        end
    elseif isa(prop, 'containers.Map')
        assertValidRefType(prop('reftype'))
        typeStr = sprintf('%s reference to %s', capitalize(prop('reftype')), prop('target_type'));
    elseif isa(prop, 'file.interface.HasProps')
        typeStrCell = cell(size(prop));
        for iProp = 1:length(typeStrCell)
            anonProp = prop(iProp);
            if isa(anonProp, 'file.Dataset') && isempty(anonProp.type)
                typeStrCell{iProp} = getPropStr(anonProp.dtype);
            elseif isempty(anonProp.type)
                typeStrCell{iProp} = 'types.untyped.Set';
            else
                typeStrCell{iProp} = anonProp.type;
            end
        end
        typeStr = strjoin(typeStrCell, '|');
    else
        typeStr = prop.type;
    end
    
    if isa(prop, 'file.interface.HasProps')
        propStrCell = cell(size(prop));
        for iProp = 1:length(prop)
            propStrCell{iProp} = prop(iProp).doc;
        end
        propStr = sprintf('(%s) %s', typeStr, strjoin(propStrCell, ' | '));
    elseif isa(prop, 'file.Attribute')
        propStr = sprintf('(%s) %s', typeStr, prop.doc);
    else
        propStr = typeStr;
    end
    
    if nargin >= 2
        propStr = [propName ' = ' propStr];
    end
end

function assertValidRefType(referenceType)
    arguments
        referenceType (1,1) string
    end
    assert( ismember(referenceType, ["region", "object"]), ...
        'NWB:ClassGenerator:InvalidRefType', ...
        'Invalid reftype found while filling description for class properties.')
end

function word = capitalize(word)
    arguments
        word (1,:) char
    end
    word(1) = upper(word(1));
end

function valueAsStr = formatValueAsString(value)
    if isnumeric(value)
        valueAsStr = num2str(value);
    elseif ischar(value)
        valueAsStr = sprintf("""%s""", value);
    else
        error('Not implemented. If you see this error, please report')
    end
end