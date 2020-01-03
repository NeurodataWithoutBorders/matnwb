classdef Manifest
    %MANIFEST a data class for defining the schema for the compound dataset Table.
    
    methods (Static)
        function Manifest = from_type(Type)
            assert(Type.get_class() == h5.const.TypeClass.Compound.constant,...
                'NWB:H5:Compound:FromType:InvalidType',...
                'Only a Compound Type can be converted into a Manifest.');
            
            Type = h5.Type(H5T.create('H5T_COMPOUND', Manifest.get_total_size()));
            
            for i = 1:length(Manifest.columns)
                offset = Manifest.get_offset(Manifest.columns{i});
                SubType = Manifest.mapping.(Manifest.columns{i});
                H5T.insert(Type.get_id(), Manifest.columns{i}, offset, SubType.get_id());
            end
            
            H5T.pack(Type.get_id());
        end
    end
    
    properties
        mapping = struct();
        columns = {}; % cell array of strings indicating field columnsing.
    end
    
    methods % lifecycle
        function obj = TableManifest(varargin)
            obj.mapping = struct;
            for i = 1:3:length(varargin)
                obj.append(varargin{i:i+2});
            end
        end
    end
    
    methods
        function insert(obj, name, Type, afterFieldName)
            assert(ischar(name),...
                'NWB:H5:Manifest:InvalidArgument',...
                'Manifest name must be a string');
            assert(isa(Type, 'h5.DefaultType'),...
                'NWB:H5:Manifest:InvalidArgument',...
                'Manifest type specifier must be one of h5.DefaultType');
            assert(ischar(afterFieldName)...
                && (isempty(afterFieldName)...
                    || any(strcmp(obj.columns, afterFieldName))),...
                'NWB:H5:TableManifest:InvalidArgument',...
                'afterFieldName should refer to an existing field name');
            
            if any(strcmp(fieldnames(obj.mapping), name))
                obj.remove(name);
            end
            
            obj.mapping.(name) = Type;
            
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
        
        function append(obj, name, Type)
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
    end
end

