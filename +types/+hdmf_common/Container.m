classdef Container < types.untyped.MetaClass & types.untyped.GroupClass
% CONTAINER - An abstract data type for a group storing collections of data and metadata. Base type for all data and metadata containers.
%
% Required Properties:
%  None



methods
    function obj = Container(varargin)
        % CONTAINER - Constructor for Container
        %
        % Syntax:
        %  container = types.hdmf_common.CONTAINER() creates a Container object with unset property values.
        %
        % Output Arguments:
        %  - container (types.hdmf_common.Container) - A Container object
        
        obj = obj@types.untyped.MetaClass(varargin{:});
        
        % Only execute validation/setup code when called directly in this class's
        % constructor, not when invoked through superclass constructor chain
        if strcmp(class(obj), 'types.hdmf_common.Container') %#ok<STISA>
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    %% EXPORT
    function refs = export(obj, writer, fullpath, refs)
        refs = export@types.untyped.MetaClass(obj, writer, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end