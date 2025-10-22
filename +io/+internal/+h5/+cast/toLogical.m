function logicalValue = toLogical(value)
% toLogical - Convert input value to logical.
%
% Syntax:
%   logicalValue = io.internal.h5.cast.toLogical(value) Converts the given 
%   h5 value to a logical value based on its type.
%
% Input Arguments:
%   value - The input value to be converted. It can be of type int8 or 
%   a cell containing a string representation of boolean values ("TRUE" or 
%   "FALSE").
%
% Output Arguments:
%   logicalValue - The corresponding logical value (true or false) after 
%   conversion.
%
% Note: Low level h5 functions (H5D.read) returns enum values as int8,
% whereas high level functions (i.e h5read) returns enum values as a cell 
% arrays of character vectors. This function accepts both types as input
% and returns a logical vector

    if isa(value, 'int8')
        logicalValue = logical(value);
    elseif isa(value, 'cell') && ismember(string(value{1}), ["TRUE", "FALSE"])
        logicalValue = strcmp('TRUE', value);
    else
        error('NWB:CastH5ToLogical:UnknownLogicalFormat', 'Could not resolve data of logical type')
    end
end
