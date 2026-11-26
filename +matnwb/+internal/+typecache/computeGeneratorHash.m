function hash = computeGeneratorHash()
% computeGeneratorHash - Hash the source code that generates classes.
%
%   hash = matnwb.internal.typecache.computeGeneratorHash() returns a
%   SHA-256 hash over the code files of the namespaces that parse
%   specifications and write classes: +file, +spec and +schemes. Any edit
%   to these files changes the hash, so cached classes made by an earlier
%   generator are not reused.

    generatorNamespaces = ["+file", "+spec", "+schemes"];
    matnwbDir = misc.getMatnwbDir();

    entries = strings(0, 1);
    for namespaceFolder = generatorNamespaces
        fileList = dir(fullfile(matnwbDir, namespaceFolder, "**", "*.m"));
        for iFile = 1:numel(fileList)
            filePath = fullfile(fileList(iFile).folder, fileList(iFile).name);
            relativePath = extractAfter(string(filePath), strlength(matnwbDir) + 1);
            % Normalize the separator so the hash is the same on every platform.
            relativePath = replace(relativePath, filesep, "/");
            entries(end+1, 1) = relativePath + newline + string(fileread(filePath)); %#ok<AGROW>
        end
    end

    % Sort by path so the hash does not depend on the order dir returns files in.
    entries = sort(entries);
    hash = matnwb.internal.typecache.computeSha256(strjoin(entries, newline));
end
