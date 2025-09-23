function tf = isNameOfA(actualClassName, className)
% isNameOfA - Determine if input is the name of the specified class 
%             (or name of a subclass of the specified class)

    if strcmp(actualClassName, className)
        tf = true;
    else
        tf = isNameOfASubclass(actualClassName, className);
    end
end

function tf = isNameOfASubclass(actualClassName, className)
    tf = false;
    
    mc = meta.class.fromName(actualClassName);
    if isempty(mc); return; end

    for i = 1:numel(mc.SuperclassList)
        currentName = mc.SuperclassList(i).Name;
        tf = types.util.internal.isNameOfA(currentName, className);
        if tf; return; end
    end
end