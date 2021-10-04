function writeNamespace(namespaceName, saveDir)
%check/load dependency namespaces
Namespace = schemes.loadNamespace(namespaceName);

if isempty(saveDir)
    saveDir = fullfile(misc.getMatnwbDir(), '+types', ['+' misc.str2validName(Namespace.Name)]);
end

if exist(saveDir, 'dir') == 7
    rmdir(saveDir, 's');
end
mkdir(saveDir);

classes = keys(Namespace.registry);
pregenerated = containers.Map; %generated nodes and props for faster dependency resolution
for i=1:length(classes)
    className = classes{i};
    [processed, classprops, inherited] = file.processClass(className, Namespace, pregenerated);
    
    if isempty(processed)
        continue;
    end
    
    fid = fopen(fullfile(saveDir, [className '.m']), 'W');
    try
        fwrite(fid, file.fillClass(className, Namespace, processed, ...
            classprops, inherited), 'char');
    catch ME
        fclose(fid);
        rethrow(ME)
    end
    fclose(fid);
end
end