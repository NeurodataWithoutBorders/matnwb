function attributeValue = processAttributeInfo(obj, attributeInfo, context)
% processAttributeInfo - Process attribute info and return attribute value

% ZARR
    
    if strcmp(attributeInfo.Datatype, 'object reference')
        attributeValue = types.untyped.ObjectView(attributeInfo.Value.value.path);
    else
        attributeValue = attributeInfo.Value;
    end

    return

    switch attributeInfo.Datatype.Class
        case 'H5T_STRING'
            % H5 String type attributes are loaded differently in releases 
            % prior to MATLAB R2020a. For details, see:
            % https://se.mathworks.com/help/matlab/ref/h5readatt.html
            attributeValue = attributeInfo.Value;
            if verLessThan('matlab', '9.8') % MATLAB < R2020a
                if iscell(attributeValue)
                    if isempty(attributeValue)
                        attributeValue = '';
                    elseif isscalar(attributeValue)
                        attributeValue = attributeInfo.Value{1};
                    else
                        attributeValue = attributeInfo.Value;
                    end
                end
            end
        case 'H5T_REFERENCE'
            fid = H5F.open(obj.Filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            aid = H5A.open_by_name(fid, context, attributeInfo.Name);
            tid = H5A.get_type(aid);
            attributeValue = io.parseReference(aid, tid, attributeInfo.Value);
            H5T.close(tid);
            H5A.close(aid);
            H5F.close(fid);
        case 'H5T_ENUM'
            if io.isBool(attributeInfo.Datatype.Type)
                % attributeInfo.Value should be cell array of strings here 
                % since MATLAB can't have arbitrary enum values.
                attributeValue = strcmp('TRUE', attributeInfo.Value);
            else
                warning('NWB:Attribute:UnknownEnum', ...
                    ['Encountered unknown enum under field `%s` with %d ' ...
                    'members. Will be saved as cell array of characters.'], ...
                    attributeInfo.Name, length(attributeInfo.Datatype.Type.Member));
            end
        otherwise
            attributeValue = attributeInfo.Value;
    end
end
