classdef PresetType < h5.Type
    %DEFAULTTYPE h5.Type generator.
    
    methods
        function data = filter(obj, data)
            switch obj
                case h5.PresetType.String
                    data = obj.filter_string(data);
                case h5.PresetType.Bool
                    data = obj.filter_bool(data);
                otherwise
                    % no op
            end
        end
    end
    
    methods (Access = private)
        function data = filter_bool(~, data)
            %FILTER_BOOL logical is arbitrarily defined as an int32 type.
            
            data = int32(data);
        end
        
        function data = filter_string(obj, data)
            %FILTER_STRING filters MATLAB character array or cell array data to readable HDF5 strings
            
            % convert to cell array of strings.
            if (iscell(data) && all(cellfun('isclass', data, 'datetime'))) ||...
                    isdatetime(data)
                data = obj.filter_datetime(data);
            elseif ~iscell(data)
                data = mat2cell(data, ones(size(data,1),1), size(data,2));
            end
            
            % sanitize
            for i=1:length(data)
                data{i} = char(unicode2native(data{i}));
            end
        end
        
        function data = filter_datetime(~, data)
            if ~iscell(data)
                data = {data};
            end
            for i=1:length(data)
                if isempty(data{i}.TimeZone)
                    data{i}.TimeZone = 'local';
                end
                data{i}.Format = 'yyyy-MM-dd''T''HH:mm:ss.SSSSSSZZZZZ'; % ISO8601
                data{i} = char(data{i});
            end
        end
    end
    
    enumeration
        ObjectReference('H5T_STD_REF_OBJ');
        DatasetRegionReference('H5T_STD_REF_DSETREG');
        Double('H5T_IEEE_F64LE');
        Single('H5T_IEEE_F32LE');
        Bool('H5T_STD_I32LE');
        I8('H5T_STD_I8LE');
        U8('H5T_STD_U8LE');
        I16('H5T_STD_I16LE');
        U16('H5T_STD_U16LE');
        I32('H5T_STD_I32LE');
        U32('H5T_STD_U32LE');
        I64('H5T_STD_I64LE');
        U64('H5T_STD_U64LE');
        String('H5T_C_S1');
    end
end

