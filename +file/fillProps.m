function s = fillProps(props, names, options)
proplines = cell(size(names));
for i=1:length(names)
    pnm = names{i};
    p = props(pnm);
    if ischar(p)
        doc = ['property of type ' p];
    elseif isa(p, 'java.util.HashMap')
        doc = ['reference to type ' p.get('target_type')];
    elseif isstruct(p)
        doc = ['table with properties {' misc.cellPrettyPrint(fieldnames(p)) '}'];
    else
        doc = p.doc;
    end
    proplines{i} = [pnm '; % ' doc];
end

if nargin >= 3
    opt = ['(' options ')'];
else
    opt = '';
end

if isempty(proplines)
    s = '';
else
    s = strjoin({...
        ['properties' opt]...
        file.addSpaces(strjoin(proplines, newline), 4)...
        'end'}, newline);
end
end