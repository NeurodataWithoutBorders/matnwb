function writeNamespace(namespace)
path = fullfile('+types', ['+' namespace.name]);
if exist(path, 'dir') == 7
    rmdir(path, 's');
end
mkdir(path);
nmk = keys(namespace.registry);
pregenprops = containers.Map; %generated props for faster dependency resolution
for i=1:length(nmk)
    k = nmk{i};
    fid = fopen(fullfile(path, [k '.m']), 'W');
    fwrite(fid, file.fillClass(k, namespace, pregenprops), 'char');
    fclose(fid);
end
end