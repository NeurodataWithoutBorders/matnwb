function template = fillTemplate(template, data)
    fields = fieldnames(data);
    for i = 1:numel(fields)
        if ~isstruct(data.(fields{i})) && ~iscell(data.(fields{i}))
            placeholder = sprintf('{{ %s }}', fields{i});
            template = strrep(template, placeholder, string(data.(fields{i})));
        end
    end
end
