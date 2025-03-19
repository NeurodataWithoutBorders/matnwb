function rootDirectoryForGeneration = findRootDirectoryForGeneratedTypes()
% findRootDirectoryForGeneratedTypes - Find directory where generated types are located
%
%   Check if any instances of types.core.NWBFile are present on MATLAB's
%   search path. If types.core.NWBFile is found, the function returns the root 
%   directory where generated types are located, otherwise the function
%   throws an error
    
    generatedTypeName = 'types.core.NWBFile';
    relPathForGeneratedType = matnwb.common.internal.classname2path(generatedTypeName);

    generatedTypeLocation = which(relPathForGeneratedType, '-all');

    if isempty(generatedTypeLocation)
        ME = MException('NWB:Types:GeneratedTypesNotFound', ...
            ['Could not find a location for generated classes of neurodata ', ...
            'types. Please check if MatNWB is properly added to MATLAB''s ' ...
            'search path and/or run generateCore() to re-generate classes.'] );
        throwAsCaller(ME)
    end
    
    if numel(generatedTypeLocation) > 1
        typeLocationAsStr = "  " + string(generatedTypeLocation); 
        typeLocationAsStr = strjoin(typeLocationAsStr, newline);

        warning('NWB:Types:MultipleGeneratedTypesFound', ...
            ['Multiple generated types were found for %s.\n', ...
            'This may indicate duplicate definitions that could lead to ', ...
            'unexpected behavior.\n\nPlease ensure that only one instance of MatNWB is ', ...
            'present on MATLAB''s search path at any time. The generated types ', ...
            'were found in the following locations:\n%s\n'], ...
            ...
            generatedTypeName, typeLocationAsStr)
    end
    
    % Remove the namespace folders from the path location of the 
    % "types.core.NWBFile" class to obtain the root directory for generated types. 
    rootDirectoryForGeneration = replace(generatedTypeLocation{1}, relPathForGeneratedType, '');
end
