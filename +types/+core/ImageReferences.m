classdef ImageReferences < types.core.NWBData & types.untyped.DatasetClass
% IMAGEREFERENCES - Ordered dataset of references to Image objects.
%
% Required Properties:
%  data



methods
    function obj = ImageReferences(varargin)
        % IMAGEREFERENCES - Constructor for ImageReferences
        %
        % Syntax:
        %  imageReferences = types.core.IMAGEREFERENCES() creates a ImageReferences object with unset property values.
        %
        %  imageReferences = types.core.IMAGEREFERENCES(Name, Value) creates a ImageReferences object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (Object reference to Image) - No description
        %
        % Output Arguments:
        %  - imageReferences (types.core.ImageReferences) - A ImageReferences object
        
        obj = obj@types.core.NWBData(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        if strcmp(class(obj), 'types.core.ImageReferences')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        % Reference to type `Image`
        val = types.util.checkDtype('data', 'types.untyped.ObjectView', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBData(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end