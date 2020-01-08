classdef Anon < nwb.interface.Exportable
    %anonymous key-value pair as an alternative to single-sized Sets
    properties
        name; %name of object
        value; %mapping value
    end
    
    methods
        function obj = Anon(nm, val)
            obj.name = '';
            obj.value = [];
            
            if nargin > 0
                obj.name = nm;
                obj.value = val;
            end
        end
        
        function set.name(obj, nm)
            assert(ischar(nm),...
                'input `name` should be a non-empty char array');
            obj.name = nm;
        end
        
        function set.value(obj, val)
            assert(isa(val, 'nwb.interface.Exportable'),...
                'NWB:Untyped:Anon:SetValue:InvalidType',...
                'Anon values only support Exportable type objects (.');
            obj.value = val;
        end
        
        function tf = isempty(obj)
            tf = isempty(obj.name);
        end
    end
    
    methods % Exportable
        function MissingViews = export(obj, Parent, ~)
            MissingViews = obj.value.export(Parent, obj.name);
        end
    end
end