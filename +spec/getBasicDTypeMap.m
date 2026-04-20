function mapping = getBasicDTypeMap()
% getBasicDTypeMap - Map basic HDMF dtypes onto MATLAB types
%
% Reference:
% https://github.com/hdmf-dev/hdmf/blob/5.1.0/src/hdmf/spec/spec.py#L31-L48

    try
        mapping = dictionary();
    catch % Fallback for older MATLAB releases
        mapping = containers.Map('UniformValues', true);
    end

    % Single precision floating point, 32 bit
    mapping('float')        = 'single';
    mapping('float32')      = 'single';

    % Double precision floating point, 64 bit
    mapping('double')       = 'double';
    mapping('float64')      = 'double';

    % Signed 64 bit integer, 64 bit
    mapping('long')         = 'int64';
    mapping('int64')        = 'int64';

    % Signed 32 bit integer, 32 bit
    mapping('int32')        = 'int32';

    % Signed 16 bit integer, 16 bit
    mapping('short')        = 'int16';
    mapping('int16')        = 'int16';

    % Signed 8 bit integer, 8 bit
    mapping('int')          = 'int8';
    mapping('int8')         = 'int8';

    % Unsigned 64 bit integer, 64 bit
    mapping('uint64')       = 'uint64';

    % Unsigned 32 bit integer, 32 bit
    mapping('uint32')       = 'uint32';

    % Unsigned 16 bit integer, 16 bit
    mapping('uint16')       = 'uint16';

    % Unsigned 8 bit integer, 8 bit
    mapping('uint')         = 'uint8';
    mapping('uint8')        = 'uint8';

    % Any numeric type (i.e., any int, uint, float), 8 to 64 bit
    mapping('numeric')      = 'numeric';

    % 8-bit Unicode, variable (UTF-8 encoding)
    mapping('text')         = 'char';
    mapping('utf')          = 'char';
    mapping('utf8')         = 'char';
    mapping('utf-8')        = 'char';

    % ASCII text, variable (ASCII encoding)
    mapping('ascii')        = 'char';
    mapping('bytes')        = 'char';

    % 8 bit integer with valid values 0 or 1, 8 bit
    mapping('bool')         = 'logical';

    % ISO 8601 datetime string, variable (ASCII encoding)
    mapping('isodatetime')  = 'datetime';
    mapping('datetime')     = 'datetime';
end
