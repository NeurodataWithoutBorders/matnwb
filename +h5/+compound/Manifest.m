classdef Manifest
    %MANIFEST a data class for defining the schema for the compound dataset Table.
    
    properties
        mapping = struct();
        columns = {}; % cell array of strings indicating field columnsing.
    end
    
    methods % lifecycle
        function obj = TableManifest(varargin)
            obj.mapping = struct;
            for i = 1:2:length(varargin)
                obj.append(varargin{i:i+1});
            end
        end
    end
    
    methods
        function insert(obj, name, DefaultType, afterFieldName)
            assert(ischar(name), 'NWB:H5:TableManifest:InvalidArgument',...
                'Manifest name must be a string');
            assert(isa(DefaultType, 'h5.DefaultType'),...
                'NWB:H5:TableManifest:InvalidArgument',...
                'Manifest type specifier must be one of h5.DefaultType');
            assert(ischar(afterFieldName)...
                && (isempty(afterFieldName)...
                    || any(strcmp(obj.columns, afterFieldName))),...
                'NWB:H5:TableManifest:InvalidArgument',...
                'afterFieldName should refer to an existing field name');
            
            if any(strcmp(fieldnames(obj.mapping), name))
                obj.remove(name);
            end
            
            obj.mapping.(name) = DefaultType;
            
            if isempty(afterFieldName)
                obj.columns{end+1} = name;
            else
                obj.columns{find(strcmp(afterFieldName, obj.columns), 1) + 1} = name;
            end
        end
        
        function remove(obj, name)
            obj.mapping = rmfield(obj.mapping, name);
            obj.columns(strcmp(name, obj.columns)) = [];
        end
        
        function append(obj, name, DefaultType)
            if isempty(obj.columns)
                afterName = '';
            else
                afterName = obj.columns{end};
            end
            
            obj.insert(name, DefaultType, afterName);
        end
        
        function size = get_total_size(obj)
            lastColumn = obj.columns{end};
            LastColumnType = obj.mapping.(lastColumn);
            size = obj.get_offset(lastColumn) + H5T.get_size(LastColumnType.get_id());
        end
        
        function size = get_offset(obj, name)
            assert(ischar(name), 'NWB:H5:TableManifest:InvalidArgument',...
                'Field name must be string');
            assert(any(strcmp(obj.columns, name)),...
                'NWB:H5:TableManifest:InvalidArgument',...
                'Field name must exist to have an offset');
            
            iName = find(strcmp(obj.columns, name), 1);
            size = 0;
            for i = 1:iName-1
                Type = obj.mapping(obj.columns{i});
                size = size + H5T.get_size(Type.get_id());
            end
        end
        
        function Type = to_type(obj)
            Type = h5.Type(H5T.create('H5T_COMPOUND', obj.get_total_size()));
            
            for i = 1:length(obj.columns)
                offset = obj.get_offset(obj.columns{i});
                SubType = obj.mapping.(obj.columns{i});
                H5T.insert(Type.get_id(), obj.columns{i}, offset, SubType.get_id());
            end
            
            H5T.pack(Type.get_id());
        end
    end
end

