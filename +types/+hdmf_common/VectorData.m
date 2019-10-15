classdef VectorData < types.hdmf_common.Data
% VECTORDATA A 1-dimensional dataset. This can be indexed using a VectorIndex to encode a 2-dimensional ragged array in 1 dimension. The first vector is at VectorData[0:VectorIndex(0)+1]. The second vector is at VectorData[VectorIndex(0)+1:VectorIndex(1)+1]. And so on.


% PROPERTIES
properties
    description; % Description of what these vectors represent.
end

methods
    function obj = VectorData(varargin)
        % VECTORDATA Constructor for VectorData
        %     obj = VECTORDATA(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % description = char
        obj = obj@types.hdmf_common.Data(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        parse(p, varargin{:});
        obj.description = p.Results.description;
        if strcmp(class(obj), 'types.hdmf_common.VectorData')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
    end
    function val = validate_description(obj, val)
        val = types.util.checkDtype('description', 'char', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.Data(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.description)
            io.writeAttribute(fid, [fullpath '/description'], obj.description);
        else
            error('Property `description` is required.');
        end
    end
end

end