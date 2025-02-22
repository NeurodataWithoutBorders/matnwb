function groupNames = listGroupNames(fileReference, h5Location)
    
    arguments
        fileReference {io.internal.h5.mustBeH5FileReference}
        h5Location (1,1) string
    end

    [fileId, fileCleanupObj] = io.internal.h5.resolveFileReference(fileReference); %#ok<ASGLU>

    % Open the specified location (group)
    [groupId, groupCleanupObj] = io.internal.h5.openGroup(fileId, h5Location); %#ok<ASGLU>

    % Use H5L.iterate to iterate over the links
    [~, ~, groupNames] = H5L.iterate(...
        groupId, "H5_INDEX_NAME", "H5_ITER_INC", 0, @collectGroupNames, {});
      
    % Define iteration function
    function [status, groupNames] = collectGroupNames(groupId, name, groupNames)
        % Only retrieve name of groups
        objId = H5O.open(groupId, name, 'H5P_DEFAULT');
        objInfo = H5O.get_info(objId);
        if objInfo.type == H5ML.get_constant_value('H5O_TYPE_GROUP')
            groupNames{end+1} = name;
        end
        H5O.close(objId);
        status = 0; % Continue iteration
    end
end
