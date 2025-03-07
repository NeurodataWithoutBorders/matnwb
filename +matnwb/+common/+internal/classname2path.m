function pathName = classname2path(typeName)
% classname2path - Return relative path name for a class name with namespaces
%
% Example:
% 
%   pathName = matnwb.common.internal.classname2path('types.core.NWBFile')
%   
%   pathName =
%         '+types/+core/NWBFile.m'

    arguments
        typeName (1,1) string
    end

    typeName = split(typeName, ".");
    typeName(1:end-1) = "+" + typeName(1:end-1);
    typeName(end) = typeName(end) + ".m";

    pathName = fullfile(typeName{:});
end
