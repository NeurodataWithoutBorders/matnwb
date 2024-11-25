function tf = isNeurodataTypeClassName(typeName)
% isNeurodataTypeClassName - Check if a name is the class name of a neurodata type.
%
%   tf = matnwb.utility.isNeurodataTypeClassName(value) returns true if a 
%       string is the class name of a class representing a neurodata type of 
%       the NWB Format
    
    arguments
        typeName (1,1) string
    end

    tf = false;
    if startsWith(typeName, 'types.') && ~startsWith('types.untyped')
        tf = true;
    end
end
