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
        proplines{i} = [pnm '; % ' requiredStr ' ' getPropStr(props(pnm))];
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