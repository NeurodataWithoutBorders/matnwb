classdef BaseImage < types.core.NWBData & types.untyped.DatasetClass
% BASEIMAGE - An abstract base type for image data. Parent type for Image and ExternalImage types.
%
% Required Properties:
%  data


% OPTIONAL PROPERTIES
properties
    description; %  (char) Description of the image.
end

methods
    function obj = BaseImage(varargin)
        % BASEIMAGE - Constructor for BaseImage
        %
        % Syntax:
        %  baseImage = types.core.BASEIMAGE() creates a BaseImage object with unset property values.
        %
        %  baseImage = types.core.BASEIMAGE(Name, Value) creates a BaseImage object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (any) - No description
        %
        %  - description (char) - Description of the image.
        %
        % Output Arguments:
        %  - baseImage (types.core.BaseImage) - A BaseImage object
        
        obj = obj@types.core.NWBData(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        if strcmp(class(obj), 'types.core.BaseImage')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
    end
    function val = validate_description(obj, val)
        val = types.util.checkDtype('description', 'char', val);
        types.util.validateShape('description', {[1]}, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBData(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.description)
            io.writeAttribute(fid, [fullpath '/description'], obj.description);
        end
    end
end

end