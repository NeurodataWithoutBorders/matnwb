function datasetConfiguration = applyCustomMatNWBPropertyNames(datasetConfiguration)
% applyCustomMatNWBPropertyNames - Processes a dataset configuration structure to apply custom MatNWB property names.
%
%   datasetConfiguration = applyCustomMatNWBPropertyNames(datasetConfiguration)
%
%   This function iterates through each field of the input structure and checks 
%   if the field corresponds to a known NWB type (using a mapping from short 
%   names to fully qualified class names). For each recognized field:
%
%      - It retrieves the full class name and determines its superclasses.
%      - If the class is a subclass of "types.untyped.MetaClass":
%           * If it is also a "types.untyped.GroupClass", the function recursively
%             processes the subgroup configuration.
%           * If it is a "types.untyped.DatasetClass", it wraps the existing 
%             configuration in a structure with a "data" property.
%      - If the field is not associated with a recognized NWB type, it remains 
%        unchanged.
%
%   Input:
%       datasetConfiguration - A 1x1 struct containing dataset configuration 
%           data.
%
%   Output:
%       datasetConfiguration - The updated configuration structure with custom 
%           property names.

    arguments
        datasetConfiguration (1,1) struct
    end
    
    classNameMap = getNwbTypesClassnameMap();

    fields = fieldnames(datasetConfiguration);

    for i = 1:numel(fields)
        
        thisField = fields{i};

        % Split of last part if the field name is "nested"
        if contains(thisField, '_')
            shortName = extractAfter(thisField, '_');
        else
            shortName = thisField;
        end

        if ~isKey(classNameMap, shortName)
            continue % Not a neurodata / nwb type
        end
        
        fullClassName = classNameMap(shortName);
        superclassNames = superclasses(fullClassName);

        if any(strcmp(superclassNames, "types.untyped.MetaClass"))
            thisSubConfig = datasetConfiguration.(thisField);
            if any(strcmp(superclassNames, "types.untyped.GroupClass"))
                % Todo: Remove this? Nested specs are currently not supported.
            elseif any(strcmp(superclassNames, "types.untyped.DatasetClass"))
                % Rename the field to include the _data suffix
                newFieldName = sprintf('%s_data', thisField);
                datasetConfiguration.(newFieldName) = thisSubConfig;
                datasetConfiguration = rmfield(datasetConfiguration, thisField);
            end
        else
            % For non-NWB types, leave the field unmodified.
        end
    end
end

function ancestorPath = getAncestorPath(initialPath, numSteps)
% getAncestorPath - Get an ancestor directory path.
%
%   ancestorPath = GETANCESTORPATH(initialPath, numSteps)
%
%   Input:
%       initialPath - A string representing the starting file or directory path.
%       numSteps    - A positive integer indicating the number of directory 
%                     levels to move up.
%
%   Output:
%       ancestorPath - A string representing the ancestor directory path.

    arguments
        initialPath (1,1) string
        numSteps (1,1) double
    end
    splitPath = split(initialPath, filesep);
    
    ancestorPath = fullfile(splitPath{1:end-numSteps}); % char output

    % Ensure the path starts with a file separator on Unix systems.
    if isunix && ~startsWith(ancestorPath, filesep)
        ancestorPath = [filesep ancestorPath];
    end
end

function map = getNwbTypesClassnameMap()
% getNwbTypesClassnameMap - Constructs a mapping between NWB type short names 
% and their fully qualified class names.
%
%   map = GETNWBTYPESCLASSNAMEMAP()
%
%   The function locates the directory containing NWB type definitions 
%   (using the location of 'types.core.NWBFile' as a reference) and searches 
%   recursively for all MATLAB class definition files (*.m). It then filters 
%   out files in the '+types/+untyped' and '+types/+util' folders.
%
%   Output:
%       map - A mapping object (either a dictionary or containers.Map) where:
%             * Keys   : Short class names (derived from file names without the .m extension).
%             * Values : Fully qualified class names in the format "types.namespace.ClassName".

    typesClassDirectory = getAncestorPath( which('types.core.NWBFile'), 2 );
    
    % Find all MATLAB class files recursively within the directory.
    L = dir(fullfile(typesClassDirectory, '**', '*.m'));
    
    % Exclude files from the '+types/+untyped' and '+types/+util' directories.
    ignore = contains({L.folder}, fullfile('+types', '+untyped')) | ...
                contains({L.folder}, fullfile('+types', '+util'));
    L(ignore) = [];

    % Extract namespace and class names from the file paths.
    [~, namespaceNames] = fileparts({L.folder});
    namespaceNames = string( strrep(namespaceNames, '+', '') );
    classNames = string( strrep( {L.name}, '.m', '') );

    % Compose fully qualified class names using the namespace and class name.
    fullClassNames = matnwb.common.composeFullClassName(namespaceNames, classNames);

    % Create a mapping from the short class names to the fully qualified class names.
    try
        map = dictionary(classNames, fullClassNames);
    catch % Fallback for older versions of MATLAB.
        map = containers.Map(classNames, fullClassNames);
    end
end
