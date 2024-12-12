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
    if startsWith(typeName, 'types.') && ~startsWith(typeName, 'types.untyped')
        mc = meta.class.fromName(typeName);
        if ~isempty(mc)
            tf = hasSuperClass(mc, 'types.untyped.MetaClass');
        end
    end
end

function tf = hasSuperClass(mc, superClassName)
% hasSuperClass - Recursively check if a meta.class object has a specific superclass.
%
%   tf = hasSuperClass(mc, superClassName) returns true if the meta.class object
%       mc has a superclass with the name superClassName, either directly or
%       indirectly (through its own superclasses).
%
%   Arguments:
%       mc - A meta.class object.
%       superClassName - The name of the superclass to check for (string).
%
%   Returns:
%       tf - Logical value indicating if the class has the specified superclass.

    arguments
        mc meta.class
        superClassName (1,1) string
    end

    % Check if the current class has the desired superclass directly.
    for i = 1:numel(mc.SuperclassList)
        if mc.SuperclassList(i).Name == superClassName
            tf = true;
            return;
        end
    end

    % If not, check recursively through each superclass.
    for i = 1:numel(mc.SuperclassList)
        if hasSuperClass(mc.SuperclassList(i), superClassName)
            tf = true;
            return;
        end
    end

    % If no match found, return false.
    tf = false;
end