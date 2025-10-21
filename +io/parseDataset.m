function parsed = parseDataset(filename, info, fullpath, Blacklist)
    %typed and untyped being container maps containing type and untyped datasets
    % the maps store information regarding information and stored data
    % NOTE, dataset name is in path format so we need to parse that out.
    name = info.Name;

    %check if typed and parse attributes
    [attrargs, Type] = io.parseAttributes(filename, info.Attributes, fullpath, Blacklist);

    fid = H5F.open(filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
    did = H5D.open(fid, fullpath);
    props = attrargs;
    datatype = info.Datatype;
    dataspace = info.Dataspace;

    parsed = containers.Map;
    afields = keys(attrargs);
    if ~isempty(afields)
        anames = strcat(name, '_', afields);
        parsed = [parsed; containers.Map(anames, attrargs.values(afields))];
    end

    % loading h5t references are required
    % unfortunately also a bottleneck
    if strcmp(datatype.Class, 'H5T_REFERENCE')
        tid = H5D.get_type(did);
        data = io.parseReference(did, tid, H5D.read(did));
        H5T.close(tid);
    elseif ~strcmp(dataspace.Type, 'simple')
        data = H5D.read(did);

        switch datatype.Class
            case 'H5T_STRING'
                if verLessThan('MATLAB', '9.8')
                    % MATLAB 2020a fixed string support for HDF5, making
                    % reading strings "consistent" with regular use.
                    data = data .';
                end
                datadim = size(data);
                if datadim(1) > 1
                    %multidimensional strings should become cellstr
                    data = strtrim(mat2cell(data, ones(datadim(1), 1), datadim(2)));
                end
            case 'H5T_ENUM'
                if io.isBool(datatype.Type)
                    data = strcmp('TRUE', data);
                else
                    warning('NWB:Dataset:UnknownEnum', ...
                        ['Encountered unknown enum under field `%s` with %d members. ' ...
                        'Will be saved as cell array of characters.'], ...
                        info.Name, length(datatype.Type.Member));
                end
        end
    else
        sid = H5D.get_space(did);
        pid = H5D.get_create_plist(did);
        isChunked = H5P.get_layout(pid) == H5ML.get_constant_value('H5D_CHUNKED');

        tid = H5D.get_type(did);
        class_id = H5T.get_class(tid);
        isNumeric = class_id == H5ML.get_constant_value('H5T_INTEGER')...
            || class_id == H5ML.get_constant_value('H5T_FLOAT');
        if isChunked && isNumeric
            data = types.untyped.DataPipe('filename', filename, 'path', fullpath);
        elseif any(dataspace.Size == 0)
            data = [];
        else
            matlabDataType = datatypeInfoToMatlabType(datatype, info);
            data = types.untyped.DataStub(filename, fullpath, dataspace.Size, matlabDataType);
        end
        H5T.close(tid);
        H5P.close(pid);
        H5S.close(sid);
    end

    if isempty(Type.typename)
        %untyped group
        parsed(name) = data;
    else
        props('data') = data;
        kwargs = io.map2kwargs(props);
        parsed = io.createParsedType(fullpath, Type.typename, kwargs{:});
    end
    H5D.close(did);
    H5F.close(fid);
end

function matlabDataType = datatypeInfoToMatlabType(datatype, info)
    
    % This function is not exhaustive, and might not be able to resolve
    % every type. If type is not detected, output will be an empty char.
    % For compound types, returns a struct (type descriptor)

    matlabDataType = '';

    if ischar(datatype.Type)
        matlabDataType = io.getMatType(datatype.Type);

    elseif isstruct(datatype.Type)
        if strcmp(datatype.Class, 'H5T_STRING')
            if strcmp(datatype.Type.Length, 'H5T_VARIABLE') && ...
                strcmp(datatype.Type.CharacterType, 'H5T_C_S1') && ...
                ismember(datatype.Type.CharacterSet, {'H5T_CSET_UTF8', 'H5T_CSET_ASCII'}) 
                matlabDataType = 'char';
            end
        elseif strcmp(datatype.Class, 'H5T_COMPOUND')
            % Extract compound type descriptor from h5info structure
            matlabDataType = extractCompoundTypeDescriptor(datatype, info);
        elseif strcmp(datatype.Class, 'H5T_ENUM')
            if io.isBool(datatype.Type)
                matlabDataType = 'logical';
            else
                warning('NWB:Dataset:UnknownEnum', ...
                    ['Encountered unknown enum under field `%s` with %d members. ' ...
                    'Will be saved as cell array of characters.'], ...
                    info.Name, length(datatype.Type.Member));
            end
        end
    end
end

function typeDescriptor = extractCompoundTypeDescriptor(datatype, info)
%EXTRACTCOMPOUNDTYPEDESCRIPTOR Extract type descriptor from h5info datatype struct
%   Creates a struct where each field corresponds to a compound member
%   and the value is the MATLAB type string for that member.

    typeDescriptor = struct();
    
    if isfield(datatype.Type, 'Member') && ~isempty(datatype.Type.Member)
        members = datatype.Type.Member;
        
        for i = 1:length(members)
            memberName = members(i).Name;
            
            % Determine MATLAB type for this member
            if ischar(members(i).Datatype)
                memberType = io.getMatType(members(i).Datatype);
            elseif isstruct(members(i).Datatype)
                % Handle nested or complex types
                if strcmp(members(i).Datatype.Class, 'H5T_COMPOUND')
                    % Recursively handle nested compound types
                    memberType = extractCompoundTypeDescriptor(members(i), info);
                elseif strcmp(members(i).Datatype.Class, 'H5T_STRING')
                    memberType = 'char';
                elseif strcmp(members(i).Datatype.Class, 'H5T_ENUM')
                    if isfield(members(i).Datatype, 'Type') && io.isBool(members(i).Datatype.Type)
                        memberType = 'logical';
                    else
                        memberType = 'char';  % Unknown enum as char
                    end
                elseif strcmp(members(i).Datatype.Class, 'H5T_REFERENCE')
                    % Distinguish between ObjectView and RegionView reference types
                    % h5info provides a Type field that indicates the specific reference type:
                    %   'H5R_OBJECT' → ObjectView (object reference)
                    %   'H5R_DATASET_REGION' → RegionView (region reference)
                    if isfield(members(i).Datatype, 'Type')
                        if strcmp(members(i).Datatype.Type, 'H5R_OBJECT')
                            memberType = 'types.untyped.ObjectView';
                        elseif strcmp(members(i).Datatype.Type, 'H5R_DATASET_REGION')
                            memberType = 'types.untyped.RegionView';
                        else
                            % Unknown reference type - default to ObjectView
                            error('NWB:ParseDataset:UnknownReferenceType', ...
                                'Unknown reference type ''%s'' in field ''%s''.', ...
                                members(i).Datatype.Type, memberName);
                        end
                    else
                        % No type information available - default to ObjectView
                        error('NWB:ParseDataset:MissingReferenceType', ...
                            'Reference type information missing for field ''%s''.', ...
                            memberName);
                    end
                else
                    memberType = 'unknown';
                end
            else
                memberType = 'unknown';
            end
            
            % Build type descriptor
            typeDescriptor.(memberName) = memberType;
        end
    end
end
