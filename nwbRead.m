function nwb = nwbRead(filename, varargin)
%NWBREAD Reads an NWB file.
%  nwb = nwbRead(filename) Reads the nwb file at filename and returns an
%  NWBFile object representing its contents.
%  nwb = nwbRead(filename, 'ignorecache') Reads the nwb file without generating classes
%  off of the cached schema if one exists.
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
%  See also GENERATECORE, GENERATEEXTENSION, NWBFILE, NWBEXPORT
ignorecache = ~isempty(varargin) && ischar(varargin{1}) &&...
    strcmp('ignorecache', varargin{1});
if ischar(filename)
    validateattributes(filename, {'char'}, {'scalartext', 'nonempty'});
    info = h5info(filename);
    try
        %check for .specloc
        fid = H5F.open(filename);
        attr_id = H5A.open(fid, '.specloc');
        ref_data = H5A.read(attr_id);
        blacklist = H5R.get_name(attr_id, 'H5R_OBJECT', ref_data);
        if ~ignorecache
            generateSpec(fid, h5info(filename, blacklist));
            rehash(); %required if we want parseGroup to read the right files.
        end
        info.Attributes(strcmp('.specloc', {info.Attributes.Name})) = [];
        H5A.close(attr_id);
        H5F.close(fid);
    catch ME
        if ~strcmp(ME.identifier, 'MATLAB:imagesci:hdf5lib:libraryError')
            rethrow(ME);
        end
        blacklist = '';
    end
    nwb = io.parseGroup(filename, info, blacklist);
    return;
elseif isstring(filename)
    validateattributes(filename, {'string'}, {'nonempty'});
else
    validateattributes(filename, {'cell'}, {'nonempty'});
    assert(iscellstr(filename));
end
nwb = NwbFile.empty(length(filename), 0);
isStringArray = isstring(filename);
for i=1:length(filename)
    if isStringArray
        fnm = filename(i);
    else
        fnm = filename{i};
    end
    info = h5info(fnm);
    nwb(i) = io.parseGroup(fnm, info);
end
end

function generateSpec(fid, specinfo)
for i=1:length(specinfo.Groups)
    location = specinfo.Groups(i).Groups(1);
    
    namespace_name = split(specinfo.Groups(i).Name, '/');
    namespace_name = namespace_name{end};
    
    filenames = {location.Datasets.Name};
    if ~any(strcmp('namespace', filenames))
        warning('MATNWB:INVALIDCACHE',...
        'Couldn''t find a `namespace` in namespace `%s`.  Skipping cache generation.',...
        namespace_name);
        return;
    end
    sourceNames = {location.Datasets.Name};
    fileLocation = strcat(location.Name, '/', sourceNames);
    schemaMap = containers.Map;
    for j=1:length(fileLocation)
        did = H5D.open(fid, fileLocation{j});
        if strcmp('namespace', sourceNames{j})
            namespaceText = H5D.read(did);
        else
            schemaMap(sourceNames{j}) = H5D.read(did);    
        end
        H5D.close(did);
    end
    
    spec.generate(namespaceText, schemaMap);
end
end
