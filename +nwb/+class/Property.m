classdef Property
    %PROPERTY Generic binding between name and type.
    
    properties
        name;
        raw_name; % if isElided, then this is the name used in the H5 name.
        type; % either a MATLAB type string, NWB type name, or NWB type primitive
        is_required; % this property needs to be non-empty by export level.
        is_elided; % this property is actually elided and represent a list of groups
        documentation; % documentation comment regarding this property.
    end
    
    methods % Lifecycle
        function obj = Property(name, type, varargin)
            p = inputParser;
            p.addOptional('Required', false, @isnumeric);
            p.addOptional('Elided', false, @isnumeric);
            p.addParameter('H5Name', name, @ischar);
            p.addParameter('Documentation', '', @ischar);
            p.parse(varargin{:});
            
            obj.name = name;
            obj.type = type;
            
            obj.is_required = p.Results.Required;
            obj.is_elided = p.Results.Elided;
            obj.raw_name = p.Results.H5Name;
            obj.documentation = p.Results.Documentation;
        end
    end
    
    methods
        function write_list(obj, file_id)
            doc = 
            fprintf(file_id, '        %s; %% %s\n', obj.name);
        end
        
        function write_validation(obj, file_id)
        end
        
        function write_export(obj, file_id)
        end
    end
end

