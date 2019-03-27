%returns sources given namespace path
function [filelist, name, dependencies] = getNamespaceInfo(namespacePath)
fid = fopen(namespacePath);
namespaceText = fread(fid, '*char')';
namecell = regexp(namespaceText, '^\s*-?\s*name:\s*(\S+)\s*$', 'tokens', 'once', 'lineanchors');
name = namecell{1};
filelist = misc.flattenTokens(...
    regexp(namespaceText, '^\s+-?\s*source:\s*(\S+)\s*$', 'tokens', 'lineanchors'));
dependencies = misc.flattenTokens(...
    regexp(namespaceText, '^\s+-?\s*namespace:\s*(\S+)\s*$', 'tokens', 'lineanchors'));
fclose(fid);
end