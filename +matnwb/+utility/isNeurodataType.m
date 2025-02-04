function tf = isNeurodataType(value)
% isNeurodataType - Check if a value / object is a neurodata type.
%
%   tf = matnwb.utility.isNeurodataType(value) returns true if the value
%       is an object of a class representing a neurodata type of the NWB Format.
%       If the input is a string representing the class name of a neurodata
%       type, the function will also return true.

    tf = false;
    if isa(value, 'char') || isa(value, 'string')
        tf = matnwb.utility.isNeurodataTypeClassName(value);
    elseif isa(value, 'types.untyped.MetaClass')
        className = class(value);
        tf = matnwb.utility.isNeurodataTypeClassName(className);
    end
end
