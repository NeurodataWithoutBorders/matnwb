function names = reservedPropertyNames()
% reservedPropertyNames - Classdef block keywords that cannot be property names
%
% MATLAB rejects these words as property identifiers because they introduce a
% block inside a classdef. A schema field with one of these names must be
% remapped to a valid MATLAB identifier (see file.internal.getMatlabPropertyName).
    names = {'events', 'methods', 'properties', 'enumeration'};
end
