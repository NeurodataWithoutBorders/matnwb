classdef NWBDataInterface < types.core.NWBContainer & types.untyped.GroupClass
% NWBDATAINTERFACE - An abstract data type for a generic container storing collections of data, as opposed to metadata.
%
% Required Properties:
%  None



methods
    function obj = NWBDataInterface(varargin)
        % NWBDATAINTERFACE - Constructor for NWBDataInterface
        %
        % Syntax:
        %  nWBDataInterface = types.core.NWBDATAINTERFACE() creates a NWBDataInterface object with unset property values.
        %
        % Output Arguments:
        %  - nWBDataInterface (types.core.NWBDataInterface) - A NWBDataInterface object
        
        obj = obj@types.core.NWBContainer(varargin{:});
        
        % Only execute validation/setup code when called directly in this class's
        % constructor, not when invoked through superclass constructor chain
        if strcmp(class(obj), 'types.core.NWBDataInterface') %#ok<STISA>
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    %% EXPORT
    function refs = export(obj, writer, fullpath, refs)
        refs = export@types.core.NWBContainer(obj, writer, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end