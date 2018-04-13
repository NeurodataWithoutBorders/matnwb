classdef MetaClass < handle
    properties(Access=protected, Hidden=true)
        associated_nwbfile; %determines if this class is actually tied to a file or not.
        dynamic_properties; % propname -> prop
        dynamic_prop_constraints % propname -> class name
        dynamic_constraints; % { classname constraints }
    end
    
    methods
        function obj = MetaClass(varargin)
            obj.dynamic_properties = containers.Map;
            obj.dynamic_prop_constraints = containers.Map;
            obj.dynamic_constraints = {};
            p = inputParser;
            p.KeepUnmatched = true;
            p.PartialMatching = false;
            p.StructExpand = false;
            addParameter(p, 'associated_nwbfile', []);
            parse(p, varargin);
            obj.associated_nwbfile = p.Results.associated_nwbfile;
        end
        
        function res = addDynamicProperty(obj, name, val)
            if any(strcmp(properties(obj), name))
                error('Cannot add a dynamic property with the same name as an object property.');
            end
            
            validate_res = obj.validateDynamicProperty(val);
            res = ~isempty(validate_res);
            
            if res
                obj.dynamic_properties(name) = val;
                obj.dynamic_prop_constraints(name) = validate_res;
            end
        end
        
        function res = getDynamicProperty(obj, name)
            res = [];
            if isKey(obj.dynamic_properties, name)
                res = obj.dynamic_properties(name);
            end
        end
        
        function export(~, loc_id)
            [fp, ndt, ~] = fileparts(mfilename('fullpath'));
            [~, namespace, ~] = fileparts(fp);
            h5util.writeAttribute(loc_id, 'namespace', ndt(2:end), 'string');
            h5util.writeAttribute(loc_id, 'neurodata_type', namespace(2:end), 'string');
        end
    end
    
    methods(Access=protected)
        function res = validateDynamicProperty(obj, val)
            res = [];
            valmc = metaclass(val);
            valparents = valmc.SuperclassList;
            for i=1:length(valparents)
                found = strcmp(obj.dynamic_constraints, valparents(i).Name);
                if any(found)
                    res = obj.dynamic_constraints{found};
                    return;
                end
            end
        end
    end
    
    methods(Sealed, Access=protected)
        %% Subsref/Subsasgn Overrides
        function varargout = subsref(obj, s)
            if strcmp('{}', s(1).type)
                error('This class only supports ''.'' and ''()'' indexing');
            end
            
            if isKey(obj.dynamic_properties, s(1).subs)
                if length(s) > 1
                    [varargout{1:nargout}] = subsref(obj.dynamic_properties(s(1).subs), s(2:end));
                else
                    varargout{1} = obj.dynamic_properties(s.subs);
                end
            else
                [varargout{1:nargout}] = builtin('subsref', obj, s);
            end
        end
        
        function obj = subsasgn(obj, s, varargin)
            if strcmp('{}', s(1).type)
                error('This class only supports ''.'' and ''()'' indexing');
            end
            
            if strcmp('()', s(1).type)
                if ~iscellstr(s.subs)
                    error('Invalid class index type.  Must be char array index');
                end
                obj.addDynamicProperty(s.subs{1}, varargin{1});
            elseif any(strcmp(properties(obj), s(1).subs))
                obj = builtin('subsasgn', obj, s, varargin);
            else
                if ~isKey(obj.dynamic_properties, s(1).subs)
                    error('No static or dynamic property %s', s(1).subs);
                end
                if length(s) > 1
                    obj.dynamic_properties(s(1).subs) = subsasgn(obj.map(s(1).subs), s(2:end), varargin);
                else
                    obj.validate_property(s.subs, varargin{1});
                    obj.map(s.subs) = varargin{1};
                end
            end
        end
    end
end