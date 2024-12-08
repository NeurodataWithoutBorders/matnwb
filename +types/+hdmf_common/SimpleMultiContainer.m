classdef SimpleMultiContainer < types.hdmf_common.Container & types.untyped.GroupClass
% SIMPLEMULTICONTAINER - A simple Container for holding onto multiple containers.
%
% Required Properties:
%  None


% OPTIONAL PROPERTIES
properties
    container; %  (Container) Container objects held within this SimpleMultiContainer.
    data; %  (Data) Data objects held within this SimpleMultiContainer.
end

methods
    function obj = SimpleMultiContainer(varargin)
        % SIMPLEMULTICONTAINER - Constructor for SimpleMultiContainer
        %
        % Syntax:
        %  simpleMultiContainer = types.hdmf_common.SIMPLEMULTICONTAINER() creates a SimpleMultiContainer object with unset property values.
        %
        %  simpleMultiContainer = types.hdmf_common.SIMPLEMULTICONTAINER(Name, Value) creates a SimpleMultiContainer object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - container (Container) - Container objects held within this SimpleMultiContainer.
        %
        %  - data (Data) - Data objects held within this SimpleMultiContainer.
        %
        % Output Arguments:
        %  - simpleMultiContainer (types.hdmf_common.SimpleMultiContainer) - A SimpleMultiContainer object
        
        obj = obj@types.hdmf_common.Container(varargin{:});
        [obj.container, ivarargin] = types.util.parseConstrained(obj,'container', 'types.hdmf_common.Container', varargin{:});
        varargin(ivarargin) = [];
        [obj.data, ivarargin] = types.util.parseConstrained(obj,'data', 'types.hdmf_common.Data', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.hdmf_common.SimpleMultiContainer')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.container(obj, val)
        obj.container = obj.validate_container(val);
    end
    function set.data(obj, val)
        obj.data = obj.validate_data(val);
    end
    %% VALIDATORS
    
    function val = validate_container(obj, val)
        namedprops = struct();
        constrained = {'types.hdmf_common.Container'};
        types.util.checkSet('container', namedprops, constrained, val);
    end
    function val = validate_data(obj, val)
        constrained = { 'types.hdmf_common.Data' };
        types.util.checkSet('data', struct(), constrained, val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.Container(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.container)
            refs = obj.container.export(fid, fullpath, refs);
        end
        if ~isempty(obj.data)
            refs = obj.data.export(fid, fullpath, refs);
        end
    end
end

end