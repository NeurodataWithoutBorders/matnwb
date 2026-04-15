function matlabType = mapType(dtype)
% mapType - Map an HDMF/NWB dtype descriptor to a MATLAB type descriptor
%
% This function normalizes the value of a schema ``dtype`` field into the
% MATLAB type representation used by MatNWB code generation.
%
% Input:
%   dtype - Schema dtype descriptor. Supported forms are:
%       * character vector basic dtype, e.g. 'int', 'float32', 'text'
%       * cell array describing a compound dtype
%       * containers.Map describing a reference dtype
%
% Output:
%   matlabType - MATLAB type descriptor corresponding to ``dtype``:
%       * character vector for basic dtypes, e.g. 'int32', 'single', 'char'
%       * struct for compound dtypes, with one field per compound member
%       * containers.Map for reference dtypes
%
% Special cases:
%   * empty, 'None', and 'any' map to 'any'
%
% Raises an error if ``dtype`` is not a supported schema dtype.

    arguments
        dtype {mustBeValidDtypeSpec}
    end

    persistent basicTypeMap
    if isempty(basicTypeMap)
        basicTypeMap = spec.getBasicDTypeMap;
    end
    
    if isempty(dtype) || (ischar(dtype) && any(strcmpi({'None', 'any'}, dtype)))
        matlabType = 'any';
        return;
    end
    
    if iscell(dtype) % Compound dtype 
        matlabType = struct();
        numTypes = length(dtype);
        for i = 1:numTypes
            typeMap = dtype{i};
            typeName = typeMap('name');
            type = file.mapType(typeMap('dtype'));
            matlabType.(typeName) = type;
        end
        return;
    end
    
    if isa(dtype, 'containers.Map') % Reference dtype 
        matlabType = dtype;
        return;
    end
    

    if isKey(basicTypeMap, dtype)
        matlabType = char( basicTypeMap(dtype) );
    else
        error('NWB:MapType:UnsupportedDtype', ...
            ['Schema attribute `dtype` returned an unsupported value "%s". ' ...
            'If this value is a supported dtype according to the HDMF/NWB ' ...
            'specification language, please raise an issue on the MatNWB ' ...
            'GitHub repository'], dtype)
    end
end

function mustBeValidDtypeSpec(dtype)
    isValid = isempty(dtype) || ischar(dtype) || iscell(dtype) || isa(dtype, 'containers.Map');

    assert(isValid, ...
        'NWB:MapType:InvalidDtype', ...
        ['Schema specification key `dtype` is invalid. Value must be of type ', ...
        'character vector, cell array or a containers.Map but was of type "%s"'], ...
        class(dtype))
end
