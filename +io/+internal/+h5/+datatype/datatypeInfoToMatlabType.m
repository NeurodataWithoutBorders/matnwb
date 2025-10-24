function matlabDataType = datatypeInfoToMatlabType(datatype, datasetName)
% datatypeInfoToMatlabType - Get MATLAB type corresponding to H5 type

    % This function is not exhaustive, and might not be able to resolve
    % every type. If type is not detected, output will be an empty char.
    % For compound types, returns a struct (type descriptor)

    arguments
        datatype (1,1) struct
        datasetName (1,1) string
    end

    matlabDataType = '';

    if ischar(datatype.Type)
        if strcmp(datatype.Class, 'H5T_REFERENCE')
            % Distinguish between ObjectView and RegionView reference types
            % h5info provides a Type field that indicates the specific reference type:
            %   'H5R_OBJECT' → ObjectView (object reference)
            %   'H5R_DATASET_REGION' → RegionView (region reference)

            referenceTypeMap = containers.Map(...
                {'H5R_OBJECT', 'H5R_DATASET_REGION'}, ...
                {'types.untyped.ObjectView', 'types.untyped.RegionView'});
            
            knownTypes = referenceTypeMap.keys();

            assert( ismember(datatype.Type, knownTypes), ...
                'NWB:ParseDataset:UnknownReferenceType', ...
                'Unknown reference type ''%s'' in field ''%s''.', ...
                datatype.Type, datasetName)

            matlabDataType = referenceTypeMap(datatype.Type);

        else
            matlabDataType = io.getMatType(datatype.Type);
        end
    elseif isstruct(datatype.Type)
        if strcmp(datatype.Class, 'H5T_STRING')
            if strcmp(datatype.Type.Length, 'H5T_VARIABLE') && ...
                strcmp(datatype.Type.CharacterType, 'H5T_C_S1') && ...
                ismember(datatype.Type.CharacterSet, {'H5T_CSET_UTF8', 'H5T_CSET_ASCII'}) 
                matlabDataType = 'char';
            end
        elseif strcmp(datatype.Class, 'H5T_COMPOUND')
            % Extract compound type descriptor from h5info structure
            matlabDataType = extractCompoundTypeDescriptor(datatype);
        elseif strcmp(datatype.Class, 'H5T_ENUM')
            if io.isBool(datatype.Type)
                matlabDataType = 'logical';
            else
                warning('NWB:Dataset:UnknownEnum', ...
                    ['Encountered unknown enum under field `%s` with %d members. ' ...
                    'Will be read as cell array of characters.'], ...
                    datasetName, length(datatype.Type.Member));
                matlabDataType = 'cell';
            end
        end
    end
end

function typeDescriptor = extractCompoundTypeDescriptor(datatype)
% extractCompoundTypeDescriptor - Extract type descriptor from h5info datatype struct
%   Creates a struct where each field corresponds to a compound member
%   and the value is the MATLAB type string for that member.

    typeDescriptor = struct();
    
    if isfield(datatype.Type, 'Member') && ~isempty(datatype.Type.Member)
        members = datatype.Type.Member;
        
        for i = 1:length(members)
            memberName = members(i).Name;

            % Recursively determine the MATLAB type for this member
            memberType = io.internal.h5.datatype.datatypeInfoToMatlabType(members(i).Datatype, memberName);
            
            % If type detection failed, throw an error
            assert(~isempty(memberType), ...
                'NWB:ParseDataset:UnknownMemberType', ...
                ['Could not determine MATLAB type for compound member ', ...
                '''%s'' with HDF5 class ''%s'''], ...
                memberName, members(i).Datatype.Class);
            
            % Build type descriptor
            typeDescriptor.(memberName) = memberType;
        end
    end
end
