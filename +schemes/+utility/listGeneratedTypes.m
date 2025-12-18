function typeClassNames = listGeneratedTypes(options)
% listGeneratedTypes - List class names for generated types
%
% Syntax:
%   typeClassNames = schemes.utility.listGeneratedTypes(options) 
%
% Input Arguments:
%  - options (name-value pairs) -
%    Optional name-value pairs. Available options:
%  
%    - OutputType (string) -
%      Specifies the type of output; can be either "class name" or 
%      "short name" (default is "class name").
%
% Output Arguments:
%  - typeClassNames (string array) - An array of class names of the generated 
%    types based on the specified output type.

    arguments
        options.OutputType (1,1) string ...
            {mustBeMember(options.OutputType, ["class name", "short name"])} = "class name"
    end

    typesDir = schemes.utility.findRootDirectoryForGeneratedTypes();
        
    listing = dir(fullfile(typesDir, '+types', '**', '*.m'));
    
    absoluteFilePaths = fullfile({listing.folder}, {listing.name});
    ignore = contains(absoluteFilePaths, {'+untyped', '+util'});
    absoluteFilePaths(ignore)=[];

    relativeFilePaths = strrep(absoluteFilePaths, typesDir, '');
    typeClassNames = strrep(relativeFilePaths, '.m', '');
    typeClassNames = strrep(typeClassNames, filesep, '.');
    typeClassNames = strrep(typeClassNames, '+', '');

    typeClassNames = string(typeClassNames);

    if strcmp(options.OutputType, 'short name')
        typeClassNamesSplit = split(typeClassNames, '.');
        typeClassNames = typeClassNamesSplit(1,:,end);
    end
end
