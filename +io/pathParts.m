function [stem, root, compoundprop] = pathParts(path)
stem = '';
sepindices = strfind(path, '/');
dotidx = strfind(path, '.');
if isempty(sepindices)
   root = path;
   return;
end
lastsepidx = sepindices(end);
stem = path(1:lastsepidx-1);

if isempty(dotidx)
    root = path(lastsepidx+1:end);
    compoundprop = [];
else
    root = path(lastsepidx+1:dotidx-1);
    compoundprop = path(dotidx+1:end);
end
end