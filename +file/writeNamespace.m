function writeNamespace(namespaceName, saveDir)
%check/load dependency namespaces
Namespace = schemes.loadNamespace(namespaceName);

if nargin < 2 || isempty(saveDir)
    saveDir = misc.getMatnwbDir();
end

saveDir = fullfile(saveDir, '+types', ['+' misc.str2validName(Namespace.name)]);

if 7 ~= exist(saveDir, 'dir')
    mkdir(saveDir);
end

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