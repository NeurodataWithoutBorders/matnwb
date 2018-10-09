function writeNamespace(namespace)
path = fullfile(fileparts(getenv('WORKSPACE')), '+types', ['+' namespace.name]);
if exist(path, 'dir') == 7
    rmdir(path, 's');
end
mkdir(path);
nmk = keys(namespace.registry);
pregenerated = containers.Map; %generated nodes and props for faster dependency resolution
for i=1:length(nmk)
    k = nmk{i};
    [processed, classprops, inherited] = file.processClass(k, namespace, pregenerated);
    
    fid = fopen(fullfile(path, [k '.m']), 'W');
    try
        fwrite(fid, file.fillClass(k, namespace, processed, ...
            classprops, inherited), 'char');
    catch ME
        fclose(fid);
        rethrow(ME)
    end
    fclose(fid);
end
end