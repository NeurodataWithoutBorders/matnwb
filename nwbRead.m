function nwb = nwbRead(filename)
%NWBREAD Reads an NWB file.
%  nwb = nwbRead(filename) Reads the nwb file at filename and returns an
%  NWBFile object representing its contents.
%
%  Requires that core and extension NWB types have been generated
%  and reside in a 'types' package on the matlab path.
%
%  Example:
%    %Generate Matlab code for the NWB objects from the core schema.
%    %This only needs to be done once.
%    generateCore('schema\core\nwb.namespace.yaml');
%    %Now we can read nwb files!
%    nwb=nwbRead('data.nwb');
%
%  See also GENERATECORE, GENERATEEXTENSIONS, NWBFILE, NWBEXPORT
validateattributes(filename, {'char', 'string'}, {'scalartext'});
info = h5info(filename);

[nwb, links, refs] = io.parseGroup(filename, info);

% we need full filepath to process this part.
if java.io.File(filename).isAbsolute
    ff = filename;
else
    ff = fullfile(pwd, filename);
end

%process links
lkeys = keys(links);
for i=1:length(links)
    lnk = lkeys{i};
    [stem, root, ~] = io.pathParts(lnk);
    nwbstem = nwb.resolve(stem);
    lnkdest = links(lnk);
    
    if strcmp(lnkdest.Type, 'soft link')
        nwbstem.(root) = nwb.resolve(lnkdest.Value{1});
    else
        nwbstem.(root) = types.untyped.External(lnkdest.Value{1}, lnkdest.Value{2});
    end
end

%process refs
rkeys = keys(refs);
for i=1:length(rkeys)
    ref = rkeys{i};
    [stem, root, compound] = io.pathParts(ref);
    if isempty(compound)
        refstem = nwb.resolve(stem);
    else
        refstem = nwb.resolve([stem '/' root]);
    end
    
    refdest = refs(ref); %can be plural
    for i=1:length(refdest)
        rd = refdest(i);
        dest = nwb.resolve(rd.path);
        if isempty(rd.region)
            %object reference
            if isempty(compound)
                refstem.ref = dest;
            else
                refstem.table.(compound){i} = dest;
            end
        else
            %region reference          
            rv = types.untyped.RegionView(dest,rd.region+1);
            
            if isempty(compound)
                refstem.ref = rv;
            else
                refstem.table.(compound){i} = rv;
            end
        end
    end
end
end