classdef LabMetaData < types.core.NWBContainer & types.untyped.GroupClass
% LABMETADATA - Lab-specific meta-data.
%
% Required Properties:
%  None



methods
    function obj = LabMetaData(varargin)
        % LABMETADATA - Constructor for LabMetaData
        %
        % Syntax:
        %  labMetaData = types.core.LABMETADATA() creates a LabMetaData object with unset property values.
        %
        % Output Arguments:
        %  - labMetaData (types.core.LabMetaData) - A LabMetaData object
        
        obj = obj@types.core.NWBContainer(varargin{:});
        if strcmp(class(obj), 'types.core.LabMetaData')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBContainer(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end