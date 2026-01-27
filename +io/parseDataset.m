function parsed = parseDataset(filename, info, fullpath, Blacklist, backend)
    %typed and untyped being container maps containing type and untyped datasets
    % the maps store information regarding information and stored data
    % NOTE, dataset name is in path format so we need to parse that out.
    arguments
        filename
        info
        fullpath
        Blacklist
        backend = []
    end
    
    % Create backend if not provided (for backward compatibility)
    if isempty(backend)
        backend = io.backend.BackendFactory.createBackend(filename);
    end
    
    name = info.Name;

    %check if typed and parse attributes
    [attrargs, Type] = io.parseAttributes(filename, info.Attributes, fullpath, Blacklist, backend);


    props = attrargs;

    parsed = containers.Map;
    afields = keys(attrargs);

    if ~isempty(afields)
        anames = strcat(name, '_', afields);
        parsed = [parsed; containers.Map(anames, attrargs.values(afields))];
    end

    data = backend.processDatasetInfo(info, fullpath);
   
    if isempty(Type.typename)
        %untyped group
        parsed(name) = data;
    else
        props('data') = data;
        kwargs = io.map2kwargs(props);
        parsed = io.createParsedType(fullpath, Type.typename, kwargs{:});
    end
end
