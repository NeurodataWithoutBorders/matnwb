function writeNamespace(namespace)
    path = fullfile('+types', ['+' namespace.name]);
    fclose('all');
    if exist(path, 'dir') == 7
        rmdir(path, 's');
    end
    mkdir(path);
    nmk = keys(namespace.registry);
    pregenprops = containers.Map; %generate props for faster dependency resolution
    cellfun(@(nmk) file.writeClass(path, nmk, namespace, pregenprops), nmk);
end