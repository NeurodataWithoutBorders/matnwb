function festr = fillExport(name, propnames, raw, props)
hdrstr = 'function [links, refs] = export(obj, filename, loc_id, path, links, refs)';
bodystr = '';
%map property names to full relative path
pathlist = procProps(propnames, raw);
for i=1:length(pathlist)
    path = pathlist{i};
    pnm = propnames{i};
    prop = props(pnm);
    writeloc = 'loc_id';
    if isempty(path)
        %constrained or open type
    elseif ~any(strcmp(propnames, path))
        %write elided values
        bodystr = strjoin({bodystr...
            ['subloc_id = io.writeElisions(loc_id, ''' path ''');']...
            }, newline);
        writeloc = 'subloc_id';
    end
    
    if isempty(path)
        suffix = pnm;
    else
        suffix = [pnm '/' path];
    end
    
    %name matches
    bodystr = [bodystr newline fillDataExport(pnm, prop, writeloc, suffix)];
end

festr = strjoin({hdrstr file.addSpaces(bodystr, 4) 'end'}, newline);
end

%returns cell array propnames -> specific path
function pplist = procProps(propnames, raw)
pplist = cell(size(propnames));
for i=1:length(propnames)
    pnm = propnames{i};
    pplist{i} = traverseRaw(pnm, raw);
end
end

function path = traverseRaw(propname, raw)
path = '';
switch class(raw)
    case 'file.Group'
        %get names of both subgroups and datasets
        gnames = cell(size(raw.subgroups));
        dsnames = cell(size(raw.datasets));
        for i=1:length(raw.subgroups)
            sg = raw.subgroups(i);
            if sg.isConstrainedSet || isempty(sg.name)
                gnames{i} = lower(sg.type);
            else
                gnames{i} = sg.name;
            end
        end
        for i=1:length(raw.datasets)
            ds = raw.datasets(i);
            if ds.isConstrainedSet
                dsnames{i} = lower(ds.type);
            else
                dsnames{i} = ds.name;
            end
        end
        allnames = [{}; gnames; dsnames];
        if any(strcmp(allnames, propname))
            path = propname;
            return;
        end
        
        %recurse with prefix
        if startsWith(propname, allnames)
            for i=1:length(gnames)
                nm = gnames{i};
                if startsWith(propname, nm)
                    suffix = propname(length(nm)+2:end);
                    
                    %relies on the fact that allnames is [gnames dsnames]
                    if i > length(gnames)
                        subraw = raw.datasets(i-length(gnames));
                    else
                        subraw = raw.subgroups(i);
                    end
                    path = [nm '/' traverseRaw(suffix, subraw)];
                end
            end
        end
    case 'file.Dataset'
        anames = cell(size(raw.attributes));
        for i=1:length(raw.attributes)
            attr = raw.attributes(i);
            anames{i} = attr.name;
        end
        if any(strcmp(anames, propname))
            path = propname;
        end
end
end

function fde = fillDataExport(name, prop, location, suffix)
if (isa(prop, 'file.Group') || isa(prop, 'file.Dataset')) && ~isempty(prop.type)
    % obj, filename, loc_id, path, links, refs
    fde = strjoin({...
        ['[l, r] = obj.' name '.export(filename, ''' location ''', [path ''' suffix '''], links, refs);']...
        'links = [links l];'...
        'refs = [refs r];'...
        }, newline);
    return;
end

if isa(prop, 'file.Group')
elseif isa(prop, 'file.Link')
    keyboard;
    fde = strjoin({...
        ['if isa(obj.' name ', ''types.untyped.External''']...
        '    io.writeExternalLink();'...
        'else'...
        '    io.writeSoftLink()'...
        'end'...
        }, newline);
else %dataset
    fde = strjoin({...
        ['if isa(obj.' name ', ''types.untyped.External''']...
        '    io.writeExternalLink();'...
        'else'...
        '    io.writeDataset();'...
        'end'...
        }, newline);
end
end