function propertyNames = getEagerLoadPropertyNames(classInfo, classProps)
% getEagerLoadPropertyNames - Identify schema metadata datasets to load eagerly.
%
% This policy is intentionally conservative. For now, only primitive scalar or
% one-dimensional text/datetime datasets on NWBFile are eager-loaded. Payload
% datasets on neurodata interfaces remain lazy.

    arguments
        classInfo
        classProps containers.Map
    end

    propertyNames = {};

    if ~isa(classInfo, 'file.Group') || ~strcmp(classInfo.type, 'NWBFile')
        return
    end

    allPropertyNames = keys(classProps);
    for iProperty = 1:numel(allPropertyNames)
        propertyName = allPropertyNames{iProperty};
        prop = classProps(propertyName);

        if isEagerLoadMetadataDataset(prop)
            propertyNames{end+1} = propertyName; %#ok<AGROW>
        end
    end
end

function tf = isEagerLoadMetadataDataset(prop)
    tf = isa(prop, 'file.Dataset') ...
        && isempty(prop.type) ...
        && any(strcmp(prop.dtype, {'char', 'datetime'})) ...
        && isScalarOrVectorShape(prop.shape);
end

function tf = isScalarOrVectorShape(shape)
    if iscell(shape) && ~isempty(shape) && iscell(shape{1})
        tf = all(cellfun(@isScalarOrVectorShape, shape));
    elseif iscell(shape)
        tf = numel(shape) <= 1;
    else
        tf = isscalar(shape);
    end
end
