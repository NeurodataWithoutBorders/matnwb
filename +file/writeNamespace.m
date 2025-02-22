function writeNamespace(namespaceName, saveDir)
%check/load dependency namespaces
Namespace = schemes.loadNamespace(namespaceName, saveDir);

classFileDir = fullfile(saveDir, '+types', ['+' misc.str2validName(Namespace.name)]);
writeNamespaceVersion(classFileDir, Namespace.version)

if ~isfolder(classFileDir)
    mkdir(classFileDir);
end

classes = keys(Namespace.registry);
pregenerated = containers.Map; %generated nodes and props for faster dependency resolution
for i=1:length(classes)
    className = classes{i};
    [processed, classprops, inherited] = file.processClass(className, Namespace, pregenerated);
    
    if ~isempty(processed)
        superClassProps = cell(1, numel(processed)-1);
        for iSuper = 2:numel(processed)
            [~, superClassProps{iSuper-1}, ~] =  file.processClass(processed(iSuper).type, Namespace, pregenerated);
        end

        fid = fopen(fullfile(classFileDir, [className '.m']), 'W');
        % Create cleanup object to close to file in case the write operation fails.
        fileCleanupObj = onCleanup(@(id) fclose(fid));
        fwrite(fid, file.fillClass(className, Namespace, processed, ...
            classprops, inherited, superClassProps), 'char');
    else
        % pass
    end
end
end

function writeNamespaceVersion(classFileDir, version)
% writeNamespaceVersion - Write function for retrieving version of
% generated namespace.
    
    functionTemplate = strjoin([...
        "function version = %s()", ...
        "    version = '%s';", ...
        "end" ...
    ], newline);
    
    functionDefinition = sprintf(functionTemplate, ...
        matnwb.common.constant.VERSIONFUNCTION, ...
        version);

    if ~isfolder(classFileDir); mkdir(classFileDir); end  
    namespaceVersionFilename = fullfile(...
        classFileDir, ...
        matnwb.common.constant.VERSIONFILE);
    
    fid = fopen(namespaceVersionFilename, 'wt');
    fwrite(fid, functionDefinition);
    fclose(fid);
end
