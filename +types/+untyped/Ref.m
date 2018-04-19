classdef Ref < handle
    properties
        path;
        region = [];
    end
    
    properties(Hidden, SetAccess=immutable)
        nwb;
        type = ''; %string requiring some type
    end
    
    methods
        function obj = Ref(path, nwb, type, region)
            if ~isa(nwb, 'nwbfile')
                error('Argument `nwb` must be a nwbfile type');
            end
            obj.nwb = nwb;
            
            obj.path = path; %validations are in set.path fcn
            if nargin >= 3
                if ~ischar(type)
                    error('Argument `type` should be a char array.');
                end
                obj.type = type;
            end
            
            
            if nargin >= 4
                obj.region = region; %validations are in set.region fcn
            end
            obj.deref();
        end
        
        function set.path(obj, val)
            if ~ischar(val)
                error('Argument `path` should be a char array.');
            end
            obj.path = val;
        end
        
        function set.region(obj, val)
            %region must be in form [start end]
            if length(val) < 2
                error('Argument `region` should be in the form of [start end]');
            end
            if ~isnumeric(val)
                error('Argument `region` should be numeric indices.');
            end
            obj.region = val(1:2);
        end
        
        function refobj = deref(obj)
            refobj = io.resolvePath(obj.nwb, obj.path);
            
            %schema-level type constraint
            if ~isempty(obj.type) && ~isa(refobj, obj.type)
                error('Reference object expected to be `%s`.  Got %s', obj.type, class(refobj));
            end
            
            if ~isempty(obj.region)
                if ~isa(refobj, 'types.core.NWBData') && ~isa(refobj, 'types.core.SpecFile')
                    error('Region reference points to a Non-dataset.');
                end
                
                if any(strcmp(properties(refobj), 'table'))
                    %return table subset
                    refobj = refobj.table(obj.region(1):obj.region(2), :);
                else %regular dataset
                    refobj = refobj.data(obj.region(1):obj.region(2));
                end
            end
        end
    end
end