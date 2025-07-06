function parentTypeClassName = getParentType(typeClassName)
    mc = meta.class.fromName(typeClassName);
    parentTypeClassName = mc.SuperclassList(1).Name;
    if strcmp(parentTypeClassName, "types.untyped.MetaClass")
        parentTypeClassName = string.empty;
    end
end
