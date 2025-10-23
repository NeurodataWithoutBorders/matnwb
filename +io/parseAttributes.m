function [args, type] = parseAttributes(filename, attributes, context, Blacklist)
% parseAttributes - Parse an attribute info structure
%
% Syntax:
%   [args, type] = io.parseAttributes(filename, attributes, context, Blacklist)
%   This function parses a given attribute info structure and returns a 
%   containers.Map of valid attributes along with neurodata type info if it 
%   exists.
%
% Input Arguments:
%   filename   - The name of the file containing attributes.
%   attributes - The attributes to be parsed.
%   context    - The context (h5 location) in which the attributes are located.
%   Blacklist  - A list of attributes to be excluded from the parsing.
%
% Output Arguments:
%   args - A containers.Map of all valid attributes.
%   type - A structure with type information (see io.getNeurodataTypeInfo)
%
% See also: io.getNeurodataTypeInfo

args = containers.Map;
type = io.getNeurodataTypeInfo(attributes);

if isempty(attributes)
    return;
end

names = {attributes.Name};

% We already got type information (if present), so we add type-specific 
% attributes to the blacklist before parsing the rest of the attribute list
Blacklist.attributes = [Blacklist.attributes, {'neurodata_type', 'namespace'}];

blacklistMask = ismember(names, Blacklist.attributes);
attributes(blacklistMask) = [];
for i=1:length(attributes)
    attr = attributes(i);

    switch attr.Datatype.Class % Normalize/postprocess some HDF5 classes
        case 'H5T_STRING'
            % H5 String type attributes are loaded differently in releases 
            % prior to MATLAB R2020a. For details, see:
            % https://se.mathworks.com/help/matlab/ref/h5readatt.html
            attributeValue = attr.Value;
            if verLessThan('matlab', '9.8') % MATLAB < R2020a
                if iscell(attr.Value)
                    if isempty(attr.Value)
                        attributeValue = '';
                    elseif isscalar(attr.Value)
                        attributeValue = attr.Value{1};
                    else
                        attributeValue = attr.Value;
                    end
                end
            end
        case 'H5T_REFERENCE'
            fid = H5F.open(filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            aid = H5A.open_by_name(fid, context, attr.Name);
            tid = H5A.get_type(aid);
            attributeValue = io.parseReference(aid, tid, attr.Value);
            H5T.close(tid);
            H5A.close(aid);
            H5F.close(fid);
        case 'H5T_ENUM'
            if io.isBool(attr.Datatype.Type)
                attributeValue = io.internal.h5.cast.toLogical(attr.Value);
            else
                warning('NWB:Attribute:UnknownEnum', ...
                    ['Encountered unknown enum under field `%s` with %d members. ' ...
                    'Will be read as cell array of characters.'], ...
                    attr.Name, length(attr.Datatype.Type.Member));
                attributeValue = io.internal.h5.postprocess.toEnumCellStr(attr.Value, attr.Datatype.Type);
            end
        otherwise
            attributeValue = attr.Value;
    end
    args(attr.Name) = attributeValue;
end
end
