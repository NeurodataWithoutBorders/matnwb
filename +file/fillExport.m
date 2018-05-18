function festr = fillExport(propnames, raw, parentName)
hdrstr = 'function refs = export(obj, loc_id, name, path, refs)';
%call parents if not empty
if isempty(parentName)
    bodystr = '';
else
    bodystr = ['refs = export@' parentName '(obj, loc_id, name, path, refs);'];
end

%export this class first unless it's NWBFile

if isa(raw, 'file.Dataset')
    loc = 'did'; %Used later in `fillDataExport` to distinguish type of parent
    %find the `data` field for the respective dataset
    % it is either data|table|ref
    if any(strcmp(propnames, 'ref'))
        datapropname = 'ref';
    elseif any(strcmp(propnames, 'table'))
        datapropname = 'table';
    else %data
        datapropname = 'data';
    end
    propcall = ['obj.' datapropname];
    bodystr = strjoin({bodystr...
        ['[' loc ' refs] = io.writeDataset(loc_id, name, [path ''/'' name], class(' propcall '), ' propcall ', refs);']...
        }, newline);
    %filter propnames to remove data prop
    propnames = propnames(~strcmp(propnames, datapropname));
else %isa group
    if strcmp(raw.type, 'NWBFile')
        loc = 'loc_id';
    else
        loc = 'gid';
        bodystr = [bodystr newline loc ' = io.writeGroup(loc_id, name);'];
    end
end

for i=1:length(propnames)
    pnm = propnames{i};
    pathProps = traverseRaw(pnm, raw);
    prop = pathProps{end};
    pathProps(end) = []; %delete prop
    
    %construct path for groups
    path = '';
    subloc = '';
    while ~isempty(pathProps) && isa(pathProps{1}, 'file.Group')
        path = [path '/' pathProps{1}.name];
        pathProps = pathProps(2:end);
    end
    if isempty(pathProps) && ~isempty(path)
        %this property has elided groups
        subloc = 'sub_gid';
        bodystr = strjoin({bodystr...
            [subloc ' = io.writeElisions(loc_id, ''' path ''');']...
            }, newline);
    elseif ~isempty(pathProps)
        %this property is dependent on an untyped dataset
        path = [path '/' pathProps{1}.name];
        subloc = 'sub_did';
        bodystr = strjoin({bodystr...
            [subloc ' = H5D.open(loc_id, ''' path ''');']...
            }, newline);
    end
    
    if isempty(subloc)
        writeloc = loc;
    else
        writeloc = subloc;
    end
    
    bodystr = [bodystr newline fillDataExport(pnm, prop, writeloc)];
    
    if ~isempty(subloc)
        switch subloc
            case 'sub_did'
                closestr = ['H5D.close(' subloc ');'];
            case 'sub_gid'
                closestr = ['H5G.close(' subloc ');'];
        end
        bodystr = [bodystr newline closestr];
    end
end

switch loc
    case 'did'
        closestr = ['H5D.close(' loc ');'];
    case 'gid'
        closestr = ['H5G.close(' loc ');'];
end
bodystr = [bodystr newline closestr];

festr = strjoin({hdrstr file.addSpaces(bodystr, 4) 'end'}, newline);
end

function path = traverseRaw(propname, raw)
path = {};
switch class(raw)
    case 'file.Group'
        %get names of both subgroups and datasets
        gnames = {};
        dsnames = {};
        lnknames = {};
        anames = {};
        
        if ~isempty(raw.attributes)
            anames = {raw.attributes.name};
        end
        
        if ~isempty(raw.subgroups)
            gnames = {raw.subgroups.name};
            lowerGroupTypes = lower({raw.subgroups.type});
            useLower = [raw.subgroups.isConstrainedSet] | cellfun('isempty', gnames);
            gnames(useLower) = lowerGroupTypes(useLower);
        end
        
        if ~isempty(raw.datasets)
            dsnames = {raw.datasets.name};
            lowerDsTypes = lower({raw.datasets.type});
            useLower = [raw.datasets.isConstrainedSet];
            dsnames(useLower) = lowerDsTypes(useLower);
        end
        
        if ~isempty(raw.links)
            lnknames = {raw.links.name};
        end
        
        if any(strcmp([anames gnames dsnames lnknames], propname))
            amatch = strcmp(anames, propname);
            gmatch = strcmp(gnames, propname);
            dsmatch = strcmp(dsnames, propname);
            lnkmatch = strcmp(lnknames, propname);
            if any(amatch)
                path = {raw.attributes(amatch)};
            elseif any(gmatch)
                path = {raw.subgroups(gmatch)};
            elseif any(dsmatch)
                path = {raw.datasets(dsmatch)};
            elseif any(lnkmatch)
                path = {raw.links(lnkmatch)};
            end
            return;
        end
        
        %find true path for elided property
        if startsWith(propname, dsnames) || startsWith(propname, gnames)
            for i=1:length(gnames)
                nm = gnames{i};
                suffix = propname(length(nm)+2:end);
                if startsWith(propname, nm)
                    res = traverseRaw(suffix, raw.subgroups(i));
                    if ~isempty(res)
                        path = [{raw.subgroups(i)} res];
                        return;
                    end
                end
            end
            for i=1:length(dsnames)
                nm = dsnames{i};
                suffix = propname(length(nm)+2:end);
                if startsWith(propname, nm)
                    res = traverseRaw(suffix, raw.datasets(i));
                    if ~isempty(res)
                        path = [{raw.datasets(i)} res];
                        return;
                    end
                end
            end
        end
    case 'file.Dataset'
        attrmatch = strcmp({raw.attributes.name}, propname);
        if any(attrmatch)
            path = {raw.attributes(attrmatch)};
        end
end
end

function fde = fillDataExport(name, prop, location)
propcall = ['obj.' name];
if isa(prop, 'file.Group') && prop.isConstrainedSet
    fde = ['refs = ' propcall '.export(' location ', '''', path, refs);'];
elseif isa(prop, 'file.Link') || isa(prop, 'file.Group') ||...
        (isa(prop, 'file.Dataset') && ~isempty(prop.type))
    % obj, loc_id, path, refs
    fde = ['refs = ' propcall '.export(' location ', ''' prop.name ''', path, refs);'];
elseif isa(prop, 'file.Dataset') %untyped dataset
    fde = strjoin({...
        ['if startsWith(class(' propcall '), ''types.untyped.'')']...
        ['    refs = ' propcall '.export(' location ', ''' name ''', [path ''/' name '''], refs);']...
        ['elseif ~isempty(' propcall ')']...
        ['    [ddid, refs] = io.writeDataset(' location ', ''' prop.name ''', [path ''/' prop.name '''], ' propcall ', refs);']...
        '    H5D.close(ddid);'...
        'end'...
        }, newline);
else
    fde = strjoin({...
        ['if ~isempty(' propcall ')']...
        ['    io.writeAttribute(' location ', ''' prop.dtype ''', ''' prop.name ''', ' propcall ');']...
        'end'...
        }, newline);
end
end