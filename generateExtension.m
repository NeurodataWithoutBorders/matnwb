function generateExtension(varargin)
    % GENERATEEXTENSION Generate Matlab classes from NWB extension schema file
    %   GENERATEEXTENSION(ext1, ext2, ..., extn)  Generate classes
    %   (Matlab m-files) from one or more NWB:N schema extension namespace
    %   files.
    %
    %   GENERATEEXTENSION(__, 'savedir', location) Generates classes in a custom directory specified
    %   by file location.
    %
    %   GENERATEEXTENSION(__, 'savedirtemp') Generates classes in the default MATLAB temp directory.
    %   This option will override any previously defined 'savedir' location.
    %
    %   A cache of schema data is generated in the 'namespaces' subdirectory in
    %   the installation directory (unless otherwise specified).
    %
    %   By default, output files are generated placed in a '+types' subdirectory in the 
    %   installation directory.
    %
    %   Example:
    %      generateExtension('schema\myext\myextension.namespace.yaml', 'schema\myext2\myext2.namespace.yaml');
    %
    %   See also GENERATECORE

    invalidArgumentErrorCode = 'NWB:GenerateExtension:InvalidArguments';

    iOptionLocation = find(strcmp(varargin, 'savedir') | strcmp(varargin, 'savedirtemp'), 1);
    if isempty(iOptionLocation)
        iOptionLocation = length(varargin) + 1;
    end

    assert(0 < min(iOptionLocation, length(varargin)), invalidArgumentErrorCode ...
        , 'generateExtension requires at least one extension to generate from.');

    options = varargin(iOptionLocation:end);
    extensions = varargin(1:(iOptionLocation-1));

    hasSaveDirTemp = any(strcmpi(varargin, 'savedirtemp'));
    if hasSaveDirTemp
        saveDir = fullfile(tempdir(), 'MatNWB');
    else
        iSaveDir = find(strcmpi(options, 'savedir'));
        if isempty(iSaveDir)
            saveDir = misc.getMatnwbDir();
        elseif iSaveDir(end) < length(options)
            saveDir = options{iSaveDir(end) + 1};
            assert(0 ~= isfile(saveDir) ...
                , invalidArgumentErrorCode ...
                , 'provided save directory "%s" must be a valid directory path.');
        else
            error(invalidArgumentErrorCode ...
                , 'incomplete or erroneous savedir argument order.');
        end
    end

    assert(all(cellfun('isclass', extensions, 'char') | cellfun('isclass', extensions, 'string')) ...
        , invalidArgumentErrorCode ...
        , 'extensions must be character arrays or strings.');

    for iExtension = 1:length(extensions)
        source = string(extensions{iExtension});
        assert(1 == isfile(source) ...
            , invalidArgumentErrorCode ...
            , 'extension file "%s" not found.', source);
        fid = fopen(source);
        namespaceText = fread(fid, '*char') .';
        fclose(fid);
        Namespaces = spec.generate(namespaceText, fileparts(source));
        for iNamespace = 1:length(NameSpaces)
            N = Namespaces(iNamespace);
            spec.saveCache(N, saveDir);
            file.writeNamespace(N.name, saveDir);
            rehash();
        end
    end
    addpath(saveDir);
end
