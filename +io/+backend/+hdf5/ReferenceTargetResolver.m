classdef ReferenceTargetResolver < handle
% ReferenceTargetResolver - Resolve HDF5 references to the paths of their targets.
%
% H5R.get_name has no path to work from when an object was reached through
% a reference, so the HDF5 library searches the whole file for it on every
% call. Resolving each reference that way makes reading a file take time
% proportional to the number of references times the number of objects,
% which dominates reading files with many references (for example one
% table per ROI, each with a VectorIndex referencing its target).
%
% This class records the address of every object in the file once, on the
% first lookup, and resolves a reference by dereferencing it and looking up
% the address of the object it points to. A reference that cannot be
% resolved this way (a null reference, a target that is not in the recorded
% paths, or an HDF5 library that does not report object addresses) is
% resolved with H5R.get_name.
%
% Usage:
%   resolver = io.backend.hdf5.ReferenceTargetResolver(objectPaths);
%   resolver = io.backend.hdf5.ReferenceTargetResolver(@() listPaths());
%   targetPath = resolver.resolve(locationId, referenceType, rawReference);
%
% The recorded addresses belong to the file at the time of the first
% lookup, so a resolver should only be used while reading one file, and
% not across writes to it.

    properties (Access = private)
        % ObjectPaths - Paths of all objects in the file, in the order HDF5
        % visits them (see listObjectPaths), or a function returning them.
        ObjectPaths

        % AddressToPath - Map from an object address (as a character key)
        % to the path the object was first found at.
        AddressToPath

        IsAddressMapBuilt (1,1) logical = false
        IsLookupAvailable (1,1) logical = true
    end

    methods
        function obj = ReferenceTargetResolver(objectPaths)
        % ReferenceTargetResolver - Create a resolver for a list of object paths.
        %
        % Input Arguments:
        %  - objectPaths (cell | function_handle) - Paths of the objects
        %    that references may point to, typically from listObjectPaths.
        %    A function returning the paths defers gathering them until a
        %    reference is first resolved.
            arguments
                objectPaths {matnwb.common.compatibility.mustBeA(objectPaths, ["cell", "function_handle"])}
            end
            obj.ObjectPaths = objectPaths;
        end

        function targetPath = resolve(obj, locationId, referenceType, rawReference)
        % resolve - Return the path of the object a reference points to.
        %
        % Input Arguments:
        %  - locationId - HDF5 identifier of the dataset or attribute that
        %    holds the reference.
        %  - referenceType - H5R_OBJECT or H5R_DATASET_REGION.
        %  - rawReference - Raw reference buffer, as read from the file.
        %
        % Output Arguments:
        %  - targetPath (char) - The same path H5R.get_name returns.
            targetPath = '';
            % A null reference is all zeros and has no target to look up.
            if obj.IsLookupAvailable && any(rawReference(:))
                targetPath = obj.lookup(locationId, referenceType, rawReference);
            end
            if isempty(targetPath)
                targetPath = H5R.get_name(locationId, referenceType, rawReference);
            end
        end
    end

    methods (Static)
        function objectPaths = listObjectPaths(groupInfo)
        % listObjectPaths - List the paths of all groups and datasets in an h5info tree.
        %
        % Paths are listed depth first with siblings in name order, which
        % is the order H5R.get_name searches in. An object reachable by
        % more than one hard link is therefore resolved to the same path
        % H5R.get_name would return.
        %
        % Input Arguments:
        %  - groupInfo (struct) - Group information as returned by h5info.
        %
        % Output Arguments:
        %  - objectPaths (cell) - Row of absolute object paths, starting
        %    with the path of groupInfo itself.
            objectPaths = {groupInfo.Name};

            numDatasets = numel(groupInfo.Datasets);
            numGroups = numel(groupInfo.Groups);
            childPaths = cell(1, numDatasets + numGroups);
            for iDataset = 1:numDatasets
                childPaths{iDataset} = joinPath( ...
                    groupInfo.Name, groupInfo.Datasets(iDataset).Name);
            end
            for iGroup = 1:numGroups
                % h5info names groups by their full path.
                childPaths{numDatasets + iGroup} = groupInfo.Groups(iGroup).Name;
            end
            % Siblings share the parent path, so sorting full paths sorts
            % them by name.
            [~, childOrder] = sort(childPaths);

            for iChild = childOrder
                if iChild <= numDatasets
                    objectPaths{end+1} = childPaths{iChild}; %#ok<AGROW>
                else
                    subgroupPaths = io.backend.hdf5.ReferenceTargetResolver.listObjectPaths( ...
                        groupInfo.Groups(iChild - numDatasets));
                    objectPaths = [objectPaths, subgroupPaths]; %#ok<AGROW>
                end
            end
        end
    end

    methods (Access = private)
        function targetPath = lookup(obj, locationId, referenceType, rawReference)
            targetPath = '';
            if ~obj.IsAddressMapBuilt
                obj.buildAddressMap(locationId);
            end
            if ~obj.IsLookupAvailable
                return
            end

            try
                objectId = H5R.dereference(locationId, referenceType, rawReference);
                objectCleanup = onCleanup(@() H5O.close(objectId)); %#ok<NASGU>
                key = objectKey(H5O.get_info(objectId));
            catch
                return
            end

            if isKey(obj.AddressToPath, key)
                targetPath = obj.AddressToPath(key);
            end
        end

        function buildAddressMap(obj, locationId)
            obj.IsAddressMapBuilt = true;
            obj.AddressToPath = containers.Map('KeyType', 'char', 'ValueType', 'char');

            try
                objectPaths = obj.ObjectPaths;
                if isa(objectPaths, 'function_handle')
                    objectPaths = objectPaths();
                end

                fileId = H5I.get_file_id(locationId);
                fileCleanup = onCleanup(@() H5F.close(fileId)); %#ok<NASGU>

                for iPath = 1:numel(objectPaths)
                    objectPath = objectPaths{iPath};
                    objectId = H5O.open(fileId, objectPath, 'H5P_DEFAULT');
                    try
                        key = objectKey(H5O.get_info(objectId));
                    catch ME
                        % An object left open would keep the file open.
                        H5O.close(objectId);
                        rethrow(ME)
                    end
                    H5O.close(objectId);

                    if ~isKey(obj.AddressToPath, key)
                        obj.AddressToPath(key) = objectPath;
                    end
                end
            catch
                % Any failure while recording addresses, including object
                % information without an address or token, leaves every
                % reference to be resolved by H5R.get_name.
                obj.IsLookupAvailable = false;
            end
        end
    end
end

function key = objectKey(objectInfo)
% objectKey - Key identifying an object within its file.
%
% HDF5 1.10 reports an object's address, and HDF5 1.12 and later an opaque
% token in its place. Both identify the object uniquely within the file.
    if isfield(objectInfo, 'addr')
        key = sprintf('%d', objectInfo.addr);
    elseif isfield(objectInfo, 'token') && isnumeric(objectInfo.token)
        key = sprintf('%d,', objectInfo.token);
    else
        error('NWB:ReferenceTargetResolver:NoObjectKey', ...
            'The HDF5 library does not report object addresses or tokens.')
    end
end

function fullPath = joinPath(parentPath, name)
    if strcmp(parentPath, '/')
        fullPath = ['/' name];
    else
        fullPath = [parentPath '/' name];
    end
end
