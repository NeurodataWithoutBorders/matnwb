%propstruct is a struct with name->docstring
%options is a string containing prop attributes (i.e. Access=private)
%s is the string output
function s = fillProps(propstruct, propertydoc, options)
propnames = fieldnames(propstruct);
if isempty(propnames)
    s = '';
    return;
end
proplines = cell(size(propnames));
for i=1:length(propnames)
    pnm = propnames{i};
    proplines{i} = ['    ' pnm '; % ' propstruct.(pnm)];
end

if nargin >= 3
    opt = ['(' options ')'];
else
    opt = '';
end

if nargin >= 2
    pd = ['% ' propertydoc];
else
    pd = '';
end

s = strjoin({...
    pd...
    ['properties' opt]...
    strjoin(proplines, newline)...
    'end'}, newline);
end