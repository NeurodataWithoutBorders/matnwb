function generateExtension(varargin)
    % GENERATEEXTENSION Generate Matlab classes from NWB extension schema file
    %   GENERATEEXTENSION(extension_path...)  Generate classes
    %   (Matlab m-files) from one or more NWB:N schema extension namespace
    %   files.  A registry of already generated core types is used to resolve
    %   dependent types.
    %
    %   A cache of schema data is generated in the 'namespaces' subdirectory in
    %   the current working directory.  This is for allowing cross-referencing
    %   classes between multiple namespaces.
    %
    %   Output files are generated placed in a '+types' subdirectory in the
    %   current working directory.
    %
    %   Example:
    %      generateExtension('schema\myext\myextension.namespace.yaml', 'schema\myext2\myext2.namespace.yaml');
    %
    %   See also GENERATECORE
    
    for iOption = 1:length(varargin)
        option = varargin{iOption};
        validateattributes(option, {'char', 'string'}, {'scalartext'} ...
            , 'generateExtension', 'extension name', iOption);
        if isstring(option)
            varargin{iOption} = char(option);
        end
    end
    
    saveDirMask = strcmp(varargin, 'savedir');
    if any(saveDirMask)
        assert(~saveDirMask(end),...
            'NWB:GenerateExtenion:InvalidParameter',...
            'savedir must be paired with the desired save directory.');
        saveDir = varargin{find(saveDirMask, 1, 'last') + 1};
        saveDirParametersMask = saveDirMask | circshift(saveDirMask, 1);
        sourceList = varargin(~saveDirParametersMask);
    else
        saveDir = misc.getMatnwbDir();
        sourceList = varargin;
    end
    
    for iNamespaceFiles = 1:length(sourceList)
        source = sourceList{iNamespaceFiles};
        validateattributes(source, {'char', 'string'}, {'scalartext'});
        
        [localpath, ~, ~] = fileparts(source);
        assert(2 == exist(source, 'file'),...
            'NWB:GenerateExtension:FileNotFound', 'Path to file `%s` could not be found.', source);
        fid = fopen(source);
        namespaceText = fread(fid, '*char') .';
        fclose(fid);
        
        Namespaces = spec.generate(namespaceText, localpath);
        
        for iNamespace = 1:length(Namespaces)
            Namespace = Namespaces(iNamespace);
            spec.saveCache(Namespace, saveDir);
            file.writeNamespace(Namespace.name, saveDir);
            rehash();
        end
    end
end
