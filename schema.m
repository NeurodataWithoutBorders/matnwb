classdef schema
    properties(Access = private)
        path;
    end
    
    methods
        function obj = schema(path)
            obj.path = path;
            jcp = javaclasspath('-all');
            fullpath = fullfile(pwd, 'jar', 'yaml.jar');
            if ~any(contains(jcp, fullpath))
                javaaddpath(fullpath);
            end
        end
        
        function typestruct = findTypeDecl(obj, typename)
            typestruct = [];
            schemas = dir(obj.path)
            for i=1:length(schemas)
                schema = schemas(i);
                if ~strcmp(schema.name, '.') && ~strcmp(schema.name, '..')
                    res = obj.findTypeInFile(schema, typename)
                    if ~isempty(res)
                        typestruct = res;
                        break;
                    end
                end
            end
        end
    end
    
    methods(Access = private)
        function typestruct = findTypeInFile(obj, file, typename)
            
        end
    end
end