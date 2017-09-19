% generic group population requiring structure of type
% struct
%    |- Attributes
%    |  - [name] -> Data
%    |- Datasets
%    |  - [name]
%    |    - Attributes
%    |    - Data
%    |- SoftLinks
%    |  - [name] -> Path
%    |- ExternLinks
%    |  - [name]
%    |    - Filename
%    |    - Path
%     - Groups
%       - [name]
%         - Attributes
%         .
%         .
%         .
function id = populateGroup(loc_id, name, structure)
plist = 'H5P_DEFAULT';
id = H5G.create(loc_id, name, plist, plist, plist);

fn = fieldnames(structure);
for i=1:length(fn)
  elem_type = fn{i};
  sub_s = structure.(elem_type);
  sub_fn = fieldnames(sub_s);
  for j=1:length(sub_fn)
    elem_name = sub_fn{i};
    data = sub_s.(elem_name);
    switch(elem_type)
      case 'Attributes'
        populateAttribute(id, elem_name, data);
      case 'Datasets'
        populateDataset(id, elem_name, data);
      case 'SoftLinks'
        H5L.create_soft(data, id, elem_name, plist, plist);
      case 'ExternLinks'
        H5L.create_external(data.Filename, data.Path, id, elem_name, plist, plist);
      case 'Groups'
        h5util.populateGroup(id, elem_name, data);
      otherwise
        error('h5util.populateGroup.InvalidStructure unable to populate');
    end
  end
end

if nargin == 0
  H5G.close(id);
end
end

function populateAttribute(loc_id, name, data)
if iscellstr(data)
  h5util.writeAttribute(loc_id, name, data, 'string');
else
  h5util.writeAttribute(loc_id, name, data);
end
end

function populateDataset(loc_id, name, datastruct)
if iscellstr(data)
  did = h5util.writeDataset(loc_id, name, datastruct.Data, 'string');
else
  did = h5util.writeDataset(loc_id, name, datastruct.Data);
end

if isfield(datastruct, 'Attributes')
  afn = fieldnames(datastruct.Attributes);
  for i=1:length(afn)
    fieldname = afn{i};
    attr_data = datastruct.Attributes.(fieldname);
    populateAttribute(did, fieldname, attr_data);
  end
end
H5D.close(did);
end