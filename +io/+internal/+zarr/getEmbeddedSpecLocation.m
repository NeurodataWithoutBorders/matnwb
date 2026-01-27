function specLocation = getEmbeddedSpecLocation(filename)
    attributes = readZattrs(filename);
    if isfield(attributes, 'x_specloc')
        specLocation = attributes.x_specloc;
    else
        specLocation = '';
    end
end
