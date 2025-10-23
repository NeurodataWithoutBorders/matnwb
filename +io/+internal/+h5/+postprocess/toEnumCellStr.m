function cellValue = toEnumCellStr(value, dataType)
% toEnumCellStr - Convert enum integer values to cell array of strings.
%
% Syntax:
%   cellValue = io.internal.h5.postprocess.toEnumCellStr(value, dataType) 
%   Converts the given enum integer values to their corresponding string 
%   representations based on the datatype definition.
%
% Input Arguments:
%   value - The input enum value(s) to be converted. Can be a scalar or 
%   array of int8 values, or a cell array of strings (from h5read).
%
%   dataType - A Datatype structure containing the enum definition a returned
%   by h5info or a H5ML.id (type identifier).
%
% Output Arguments:
%   cellValue - Cell array of strings containing the enum member names
%   corresponding to the input values.
%
% Note: Low level h5 functions (H5D.read) return enum values as int8,
% whereas high level functions (i.e h5read) return enum values as cell 
% arrays of character vectors. This function accepts both types as input.

    % If already a cell array of strings, return as-is
    if iscellstr(value) %#ok<ISCLSTR> - We don't expect string arrays here
        cellValue = value;
        return;
    end

    % Build a lookup map from enum values to names
    if isstruct(dataType)
        enumMap = enumMapFromTypeStruct(dataType);
    elseif isa(dataType, 'H5ML.id')
        enumMap = enumMapFromTypeId(dataType);
    end

    % Convert values to cell array of strings
    valueSize = size(value);
    cellValue = cell(valueSize);

    enumValues = enumMap.keys();
    enumValues = cast([enumValues{:}], 'like', value);

    assert(all(ismember(value, enumValues)), ...
        'NWB:CastH5ToEnumCellStr:UnknownValue', ...
        ['Enum data values do not match the enum member values in the ', ...
        'enum type definition'])
    
    for i = 1:numel(enumValues)
        IND = value == enumValues(i);
        cellValue(IND) = deal({enumMap(enumValues(i))});
    end
end

function enumMap = enumMapFromTypeStruct(dataType)
% Build a lookup map from enum values to names from h5info Datatype struct
    enumMap = containers.Map('KeyType', 'int32', 'ValueType', 'char');
    for i = 1:length(dataType.Member)
        memberValue = dataType.Member(i).Value;
        memberName = dataType.Member(i).Name;
        enumMap(int32(memberValue)) = memberName;
    end
end

function enumMap = enumMapFromTypeId(typeId)
% Build a lookup map from enum values to names using HDF5 type ID
    enumMap = containers.Map('KeyType', 'int32', 'ValueType', 'char');
    
    % Get number of enum members
    numMembers = H5T.get_nmembers(typeId);
    
    % Iterate through each member (0-indexed)
    for iMember = 0:(numMembers-1)
        memberName = H5T.get_member_name(typeId, iMember);
        memberValue = H5T.get_member_value(typeId, iMember);
        enumMap(int32(memberValue)) = memberName;
    end
end
