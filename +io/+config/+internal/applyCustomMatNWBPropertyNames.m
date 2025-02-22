function datasetConfiguration = applyCustomMatNWBPropertyNames(datasetConfiguration)
    
    arguments
        datasetConfiguration (1,1) struct
    end
    
    fields = fieldnames(datasetConfiguration);
    classNameMap = getNwbTypesClassnameMap();

    for i = 1:numel(fields)
        
        thisField = fields{i};
        if ~isKey(classNameMap, thisField)
            continue
        end
        
        fullClassName = classNameMap(thisField);
        superclassNames = superclasses(fullClassName);

        if any(strcmp(superclassNames, "types.untyped.MetaClass"))
            thisSubConfig = datasetConfiguration.(thisField);
            if any(strcmp(superclassNames, "types.untyped.GroupClass"))
                % Recursively process subgroups
                datasetConfiguration.(thisField) = ...
                    io.config.internal.applyCustomMatNWBPropertyNames(thisSubConfig);
            elseif any(strcmp(superclassNames, "types.untyped.DatasetClass"))
                % MatNWB adds a "data" property on Dataset type classes,
                % which is not originally part of the schema.
                datasetConfiguration.(thisField) = struct('data', thisSubConfig);
            else
                error('NWB:UnexpectedError', 'Something unexpected happened.')
            end
        else
            % Do nothing.
        end
    end
end

function ancestorPath = getAncestorPath(initialPath, numSteps)
    arguments
        initialPath (1,1) string
        numSteps (1,1) double
    end
    splitPath = split(initialPath, filesep);
    
    ancestorPath = fullfile(splitPath{1:end-numSteps}); % char output
    if isunix && ~startsWith(ancestorPath, filesep)
        ancestorPath = [filesep ancestorPath];
    end
end

function map = getNwbTypesClassnameMap()

    typesClassDirectory = getAncestorPath( which('types.core.NWBFile'), 2 );
    
    % Find names of all nwb types:
    L = dir(fullfile(typesClassDirectory, '**', '*.m'));
    ignore = contains({L.folder}, fullfile('+types', '+untyped')) | ...
                contains({L.folder}, fullfile('+types', '+util'));
    L(ignore) = [];


    [~, namespaceNames] = fileparts({L.folder});
    namespaceNames = string( strrep(namespaceNames, '+', '') );
    classNames = string( strrep( {L.name}, '.m', '') );

    fullClassNames = compose("types.%s.%s", namespaceNames', classNames');
    try
        map = dictionary(classNames', fullClassNames);
    catch % If older version of MATLAB
        map = containers.Map(classNames, fullClassNames);
    end
end