function rootDirectoryForGeneration = findRootDirectoryForGeneratedTypes()
% findRootDirectoryForGeneratedTypes - Find directory where generated types are located
%
%   Check if any instances of types.core.NWBFile are present on MATLAB's
%   search path. If types.core.NWBFile is found, the function returns the root 
%   directory where generated types are located, otherwise the function
%   throws an error
    
    generatedTypeName = 'types.core.NWBFile';
    generatedTypeLocation = which(generatedTypeName, "-all");

    if isempty(generatedTypeLocation)
        error('NWB:Types:GeneratedTypesNotFound', ...
            ['Could not find a location for generated classes for neurodata ', ...
            'types. Please check if MatNWB is properly added to MATLAB''s ' ...
            'and/or run generateCore() to re-generate classes.'] )
    end
    
    if numel(generatedTypeLocation) > 1
        warning('NWB:Types:MultipleGeneratedTypesFound', ...
            ['Multiple generated types was found for %s.\n', ...
            'This may indicate duplicate definitions that could lead to ', ...
            'unexpected behavior. Please ensure that only one instance of MatNWB is ', ...
            'present on MATLAB''s search path at any time.'], generatedTypeName)
    end
    
    % Remove the namespace folders from the path location of the 
    % "types.core.NWBFile" class to obtain the root directory for generated types. 
    relPathForGeneratedType = matnwb.common.internal.classname2path(generatedTypeName);
    rootDirectoryForGeneration = replace(generatedTypeLocation{1}, relPathForGeneratedType, '');
end
