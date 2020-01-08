classdef Manifest
    %MANIFEST a data class for defining the schema for the compound dataset Table.
    
    methods (Static)
        function Manifest = from_type(Type)
            MSG_ID_CONTEXT = 'NWB:H5:Compound:Manifest:FromType:';
            assert(isa(Type, 'h5.Type'), [MSG_ID_CONTEXT 'InvalidArgument'],...
                'Type must be a h5.Type');
            assert(Type.typeClass == h5.const.TypeClass.Compound.constant,...
                [MSG_ID_CONTEXT 'InvalidTypeClass'],...
                'A Manifest cannot be a converted from a non-compound Type.');
            
            arguments = cell(H5T.get_nmembers(Type.get_id()) * 2, 1);
            
            for i = 1:2:length(arguments)
                membno = (i - 1) / 2;
                arguments{i} = H5T.get_member_name(Type.get_id(), membno);
                arguments{i + 1} = h5.Type(H5T.get_member_type(Type.get_id(), membno));
            end
            
            Manifest = h5.compound.Manifest(arguments{:});
        end
    end
    
    properties
        mapping = struct();
        columns = {}; % cell array of strings indicating field columnsing.
    end
    
    methods % lifecycle
        function obj = Manifest(varargin)
            assert(0 == mod(length(varargin), 2),...
                'NWB:H5:Compound:Manifest:InvalidNumberOfArguments',...
                ['Manifest takes in exactly 2 `push` arguments at a time in the '...
                'form of (`name`, `Type`)']);
            for i = 1:2:length(varargin)
                obj.push(varargin{i:i+1});
            end
        end
    end
    
    methods
        function push(obj, name, Type, varargin)
            MSG_ID_CONTEXT = 'NWB:H5:Compound:Manifest:Push:';
            assert(ischar(name),...
                [MSG_ID_CONTEXT 'InvalidArgument'],...
                'Manifest name must be a character array.');
            assert(isa(Type, 'h5.Type'),...
                [MSG_ID_CONTEXT 'InvalidArgument'],...
                'Manifest type specifier must be one of h5.Type');
            
            p = inputParser;
            p.addParameter('after', '');
            p.parse(varargin{:});
            afterFieldName = p.Results.after;
            
            assert(ischar(afterFieldName), [MSG_ID_CONTEXT 'InvalidKeywordArgument'],...
                '`after` field name must be a character array');
            
            if isempty(afterFieldName)
                pushIndex = length(obj.columns) + 1;
            else
                columnMask = strcmp(afterFieldName, obj.columns);
                assert(any(columnMask),...
                    [MSG_ID_CONTEXT 'AfterFieldNameNotFound'],...
                    '`after` field name does not exist in columns');
                pushIndex = find(strcmp(afterFieldName, obj.columns), 1);
            end
            
            if any(strcmp(obj.columns, name))
                obj.remove(name);
            end
            
            obj.mapping.(name) = Type;
            obj.columns{pushIndex} = name;
        end
        
        function remove(obj, name)
            obj.mapping = rmfield(obj.mapping, name);
            obj.columns(strcmp(name, obj.columns)) = [];
        end
        
        function size = get_total_size(obj)
            if isempty(obj.columns)
                size = 0;
                return;
            end
            
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

