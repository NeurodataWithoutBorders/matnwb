function matlabType = mapType(dtype)
% mapType - Map an HDMF/NWB dtype descriptor to a MATLAB type descriptor
%
% This function normalizes the value of a schema ``dtype`` field into the
% MATLAB type representation used by MatNWB code generation.
%
% Input:
%   dtype - Schema dtype descriptor. Supported forms are:
%       * character vector describing basic dtype, e.g. 'int', 'float32', 'text'
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

    persistent basicTypeMap
    if isempty(basicTypeMap)
        basicTypeMap = spec.getBasicDTypeMap();
    end

    if ischar(dtype) % Basic dtype
        if any(strcmpi({'None', 'any'}, dtype))
            matlabType = 'any';
        else
            try
                matlabType = basicTypeMap(dtype);
                matlabType = char(matlabType);
            catch
                error('NWB:MapType:UnsupportedDtype', ...
                    ['Schema attribute `dtype` returned an unsupported value "%s". ' ...
                    'If this value is a supported dtype according to the HDMF/NWB ' ...
                    'specification language, please raise an issue on the MatNWB ' ...
                    'GitHub repository'], dtype)
            end
        end

    elseif iscell(dtype) % Compound dtype 
        matlabType = struct();
        numTypes = numel(dtype);
        for i = 1:numTypes
            typeMap = dtype{i};
            typeName = typeMap('name');
            type = file.mapType(typeMap('dtype'));
            matlabType.(typeName) = type;
        end
    
    elseif isa(dtype, 'containers.Map') % Reference dtype 
        matlabType = dtype;
    
    elseif isempty(dtype)
        matlabType = 'any';
    
    else
        error(...
        'NWB:MapType:InvalidDtype', ...
        ['Schema `dtype` specification key must be a character vector, ', ...
         'cell array, or containers.Map; got %s.'], class(dtype))
    end
end
