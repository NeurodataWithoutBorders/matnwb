function festr = fillExport(propnames, raw, parentName)
hdrstr = 'function refs = export(obj, fid, fullpath, refs)';

if isempty(parentName)
    bodystr = '';
else
    bodystr = ['refs = export@' parentName '(obj, fid, fullpath, refs);'];
end

nameparts = '[path, name, ~] = fileparts(fullpath);';

if isempty(bodystr)
    bodystr = nameparts;
else
    bodystr = [bodystr newline nameparts];
end

if isa(raw, 'file.Dataset')
    loc = 'did';
    if any(strcmp(propnames, 'data'))
        %find the `data` field for the respective dataset
        bodystr = strjoin({bodystr...
            ['if any(strcmp(class(obj.data), {''types.untyped.DataStub''...'...
                '''types.untyped.ObjectView'' ''types.untyped.RegionView''}))']...
            '    try'...
            '        refs = obj.data.export(fid, fullpath, refs);'...
            '    catch'...
            '        refs(fullpath) = obj.data;'...
            '        return;'...
            '    end'...
            'elseif isa(obj.data, ''table'')'...
            '    try'...
            ['        ' loc ' = io.writeTable();']...
            '    catch'...
            '        refs(fullpath) = obj.data;'...
            '        return;'...
            '    end'...
            'else'...
            ['    ' loc ' = io.writeDataset(fid, fullpath, class(obj.data), obj.data);']...
            'end'...
            }, newline);
        %filter propnames to remove data prop
        propnames = propnames(~strcmp(propnames, 'data'));
    else
        %did is inherited so reopen the data field
        bodystr = strjoin({bodystr...
            'try'...
            ['    ' loc ' = H5D.open(fid, fullpath);']...
            'catch'... %if the data contains a reference, it will be skipped.
            '    return;'...
            'end'}, newline);
    end
else %group
    if strcmp(raw.type, 'NWBFile')
        loc = 'loc_id';
    else
        loc = 'gid';
        bodystr = [bodystr newline loc ' = io.writeGroup(fid, fullpath);'];
    end
end

if isempty(parentName)
    %Metaclass needs to be added after the class is made
    bodystr = [bodystr newline 'refs = export@types.untyped.MetaClass(obj, nwb, ' loc ', name, path, refs);'];
end

for i=1:length(propnames)
    pnm = propnames{i};
    pathProps = traverseRaw(pnm, raw);
    prop = pathProps{end};
    pathProps(end) = []; %delete prop
    
    %construct path for groups
    elisions = '';
    subloc = '';
    while ~isempty(pathProps) && isa(pathProps{1}, 'file.Group')
        elisions = [elisions '/' pathProps{1}.name];
        pathProps = pathProps(2:end);
    end
    elisions = elisions(2:end);
    if isempty(pathProps) && ~isempty(elisions)
        %this property has elided groups
        subloc = 'sub_gid';
        propstr = [subloc ' = io.writeElisions(loc_id, ''' elisions ''');'];
    elseif ~isempty(pathProps)
        %this property is dependent on an untyped dataset
        propname = pathProps{1}.name;
        if isempty(elisions)
            elisions = propname;
        else
            elisions = [elisions '/' propname];
        end
        subloc = 'sub_did';
        propstr = [subloc ' = H5D.open(loc_id, [fullpath ''/' elisions ''']);'];
    else
        propstr = '';
    end
    
    if isempty(subloc)
        writeloc = loc;
    else
        writeloc = subloc;
    end
    
    if isempty(propstr)
        propstr = fillDataExport(pnm, prop, writeloc, elisions);
    else
        propstr = [propstr newline fillDataExport(pnm, prop, writeloc, elisions)];
    end
    
    if ~isempty(subloc)
        switch subloc
            case 'sub_did'
                closestr = ['H5D.close(' subloc ');'];
            case 'sub_gid'
                closestr = ['H5G.close(' subloc ');'];
        end
        propstr = [propstr newline closestr];
        if strcmp(subloc, 'sub_did')
            %since it's possible for datasets to be nonexistent, we have to
            %check for the case when the datasets doesn't actually exist.
            propstr = strjoin({...
                'try'...
                file.addSpaces(propstr, 4)...
                'catch'...
                'end'}, newline);
        end
    end
    bodystr = [bodystr newline propstr];
end

switch loc
    case 'did'
        closestr = ['H5D.close(' loc ');'];
    case 'gid'
        closestr = ['H5G.close(' loc ');'];
    otherwise
        closestr = '';
end
if ~isempty(closestr)
    bodystr = [bodystr newline closestr];
end

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

function fde = fillDataExport(name, prop, location, elisions)
propcall = ['obj.' name];
if isempty(elisions)
    fpcall = 'fullpath';
else
    fpcall = ['[fullpath ''/' elisions ''']'];
end
if (isa(prop, 'file.Group') || isa(prop, 'file.Dataset')) && prop.isConstrainedSet
    fde = ['refs = ' propcall '.export(' location ', nwb, '''', ' fpcall ', refs);'];
elseif isa(prop, 'file.Link') || isa(prop, 'file.Group') ||...
        (isa(prop, 'file.Dataset') && ~isempty(prop.type))
    % obj, loc_id, path, refs
    fde = ['refs = ' propcall '.export(' location ', nwb, ''' prop.name ''', ' fpcall ', refs);'];
elseif isa(prop, 'file.Dataset') %untyped dataset
    fde = strjoin({...
        ['if startsWith(class(' propcall '), ''types.untyped.'')']...
        ['    refs = ' propcall '.export(' location ', nwb, ''' prop.name ''', ' fpcall ', refs);']...
        ['elseif ~isempty(' propcall ')']...
        ['    ddid = io.writeDataset(' location ', ''' prop.name ''', class(' propcall '), ' propcall ');']...
        '    H5D.close(ddid);'...
        'end'...
        }, newline);
else
    fde = ['io.writeAttribute(' location ', ''' prop.dtype ''', ''' prop.name ''', ' propcall ');'];
end
if ~prop.required
    %surround with check for empty array
    fde = strjoin({...
        ['if ~isempty(' propcall ')']...
        file.addSpaces(fde, 4)...
        'end'}, newline);
end
end