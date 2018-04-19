classdef DynamicClass < handle & matlab.mixin.CustomDisplay
    properties(Access=protected)
        map;
        validators;
        allowAddProp;
    end
    
    methods
        function obj = DynamicClass
            obj.map = containers.Map;
            obj.schema = containers.Map;
            obj.allowAddProp = false;
        end
        
        function validate_property(obj, name, val)
            if isKey(obj.schema, name)
                feval(obj.schema(name), val);
            elseif ~obj.allowAddProp
                error('This class does not allow adding properties.');
            end
        end
        
        function export(~, loc_id)
            %write namespace and class name
            [path, classname, ~] = fileparts(mfilename('fullpath'));
            [~, namespacename, ~] = fileparts(path);
            h5util.writeAttribute(loc_id, 'namespace', namespacename(2:end), 'string');
            h5util.writeAttribute(loc_id, 'neurodata_type', classname(2:end), 'string');
        end
    end
    
    methods(Sealed, Access=protected)
        %% Subsref/Subsasgn Overrides
        
        function varargout = subsref(obj, s)
            if strcmp('{}', s(1).type)
                error('subcont only supports ''.'' and ''()'' indexing');
            end
            
            if length(s) > 1
                [varargout{1:nargout}] = subsref(obj.map(s(1).subs), s(2:end));
            else
                varargout{1} = obj.map(s.subs);
            end
        end
        
        function obj = subsasgn(obj, s, varargin)
            if strcmp('{}', s(1).type)
                error('subcont only supports ''.'' and ''()'' indexing');
            end
            
            if strcmp('()', s(1).type)
                obj.validate_property(s.subs, varargin{1});
                obj.map(s.subs{:}) = varargin{1};
            else
                if length(s) > 1
                    obj.map(s(1).subs) = subsasgn(obj.map(s(1).subs), s(2:end), varargin);
                else
                    obj.validate_property(s.subs, varargin{1});
                    obj.map(s.subs) = varargin{1};
                end
            end
        end
        
        %% Custom Display Overrides
        function displayScalarObject(obj)
            if isempty(obj.map)
                disp(matlab.mixin.CustomDisplay.getSimpleHeader(obj));
            else
                disp(['  ' matlab.mixin.CustomDisplay.getClassNameForHeader(obj)...
                    ' with properties:' newline]);
                mk = keys(obj.map);
                maxwordlen = 0;
                for i=1:length(mk)
                    mklen = length(mk{i});
                    if mklen > maxwordlen
                        maxwordlen = mklen;
                    end
                end
                
                for i=1:length(mk)
                    mknm = mk{i};
                    val = obj.map(mknm);
                    if ischar(val)
                        val = ['''' val ''''];
                    end
                    disp([repmat(' ', 1, (maxwordlen - length(mknm)) + 4)...
                        mknm ': ' strtrim(evalc('disp(val)'))]);
                end
                disp(' ');
            end
        end
        
        function displayNonScalarObject(obj)
            disp([strjoin(size(obj), 'x') ' ' getClassNameForHeader(obj)]);
        end
    end
end