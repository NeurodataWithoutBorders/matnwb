function resolvedOptions = resolveDatasetConfigForDataType(datasetConfig, nwbObject, datasetName)
% resolveDatasetConfigForDataType - Resolve the dataset configuration for individual neurodata types
%   This function resolves the dataset configuration options for a given NWB 
%   object by traversing the object hierarchy and combining options from the 
%   most specific type to the base type, as defined in the datasetConfig 
%   structure.
%
%   Input:
%       datasetConfig (struct): A struct representation of the dataset configuration JSON.
%       nwbObject (types.untyped.MetaClass): An NWB object whose dataset configuration will be resolved.
%
%   Output:
%       resolvedOptions (struct): A struct containing the resolved dataset configuration options.

    arguments
        datasetConfig (1,1) struct
        nwbObject (1,1) types.untyped.MetaClass
        datasetName (1,1) string
    end

    % Initialize resolvedOptions with default options.
    resolvedOptions = datasetConfig.Default;
    datasetConfigKeys = fieldnames(datasetConfig);
    
    % Get the NWB object type hierarchy (from most specific to base type)
    typeHierarchy = getTypeHierarchy(nwbObject);

    % Traverse the type hierarchy to resolve options
    for i = numel(typeHierarchy):-1:1
        typeName = typeHierarchy{i};

        thisDatasetConfigKey = sprintf('%s_%s', typeName, datasetName);

        isMatchedKey = endsWith(datasetConfigKeys, thisDatasetConfigKey);
            
        if any( isMatchedKey )
            assert( sum(isMatchedKey) == 1, 'Expected exactly one match')
            datasetOptions = datasetConfig.(datasetConfigKeys{isMatchedKey});
            resolvedOptions = mergeStructs(resolvedOptions, datasetOptions);
        end
    end
end

function typeHierarchy = getTypeHierarchy(nwbObject)
% getTypeHierarchy - Retrieve the type hierarchy of an NWB object.
%   This function returns a cell array of type names, starting from the specific
%   type of the given NWB object up to its base type.

    typeHierarchy = {};  % Initialize an empty cell array
    currentType = class(nwbObject); % Start with the specific type

    while ~isempty(currentType)
        shortClassName = regexp(currentType, '[^.]+$', 'match', 'once');
        typeHierarchy{end+1} = shortClassName; %#ok<AGROW>

        % Use MetaClass information to get the parent type
        metaClass = meta.class.fromName(currentType);
        if isempty(metaClass.SuperclassList)
            break; % Reached the base type
        end
        currentType = metaClass.SuperclassList(1).Name;
    end
end

function merged = mergeStructs(baseStruct, newStruct)
% mergeStructs - Merge two structs, with fields in newStruct overriding those in baseStruct.

    merged = baseStruct; % Start with the base struct

    fields = fieldnames(newStruct);
    for i = 1:numel(fields)
        field = fields{i};
        if isstruct(newStruct.(field)) && isfield(baseStruct, field) && isstruct(baseStruct.(field))
            % Recursively merge if both fields are structs
            merged.(field) = mergeStructs(baseStruct.(field), newStruct.(field));
        else
            % Otherwise, override the field
            merged.(field) = newStruct.(field);
        end
    end
end
