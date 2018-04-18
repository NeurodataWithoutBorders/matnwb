function [parsed, refs] = parseDatasets(filename, ds_info)
%typed and untyped being container maps containing type and untyped datasets
% the maps store information regarding information and stored data
% NOTE, dataset name is in path format so we need to parse that out.

parsed = [];
refs = containers.Map;

for i=1:length(ds_info)
    ds = ds_info(i);
    [~, root] = io.pathParts(ds.Name);
    
    %check if typed and parse attributes
    [attrargs, typename] = io.parseAttributes(ds.Attributes);
    
    if isempty(typename) %a Group's properties
        parsed = containers.Map;
        afields = fieldnames(attrargs);
        for j=1:length(afields)
            attr = afields{i};
            parsed([root '_' attr]) = attrargs(attr);
        end
        parsed(root) = h5read(filename, ds.Name);
        return;
    end
    % given name, either a:
    %   regular dataset (currently dne)
    %   direct reference (ElectrodeTableRegion)
    %   compound data w/ reference (ElectrodeTable)
    parsedclass = containers.Map;
    
    fid = H5F.open(filename);
    did = H5D.open(fid, ds.Name);
    data = H5D.read(did); %this way, references are not automatically resolved
    
    datatype = ds.Datatype;
    if strcmp(datatype.Class, 'H5T_REFERENCE')
        reftype = datatype.Type;
        switch reftype
            case 'H5R_OBJECT'
                %TODO when included in schema
            case 'H5R_DATASET_REGION'
                sid = H5R.get_region(did, reftype, data);
                [start, finish] = H5S.get_select_bounds(sid);
                parsedclass('target') = H5R.get_name(did, reftype, data);
                parsedclass('region') = [start+1 finish];
                H5S.close(sid);
        end
    elseif strcmp(datatype.Class, 'H5T_COMPOUND')
        compound = datatype.Type.Member;
        for j=1:length(compound)
            comp = compound(j);
            if strcmp(comp.Datatype.Class, 'H5T_REFERENCE')
            end
        end
    end
    
    parsed = parsedclass;
    
    H5D.close(did);
    H5F.close(fid);
end
end