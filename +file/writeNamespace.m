function writeNamespace(namespaceName)
%check/load dependency namespaces
Namespace = schemes.loadNamespace(namespaceName);
generatedPath = fullfile(pwd, 'generated');
if contains(path(), generatedPath)
    rmpath(generatedPath);
end
namespacePath = fullfile(generatedPath, ['+' Namespace.name]);
if exist(namespacePath, 'dir') == 7
    rmdir(namespacePath, 's');
end
mkdir(namespacePath);
classes = keys(Namespace.registry);
pregenerated = containers.Map; %generated nodes and props for faster dependency resolution
for i=1:length(classes)
    className = classes{i};
    [processed, classprops, inherited] = file.processClass(className, Namespace, pregenerated);
    
    if isempty(processed)
        continue;
    end
    
    fid = fopen(fullfile(namespacePath, [className '.m']), 'W');
    try
        fwrite(fid, file.fillClass(className, Namespace, processed, ...
            classprops, inherited), 'char');
    catch ME
        fclose(fid);
        rethrow(ME)
    end
    fclose(fid);
end
addpath(generatedPath);
end