function data = loadSelections(obj, selections)
% LOADSELECTIONS read several selections in one pass over the dataset.
% DATA = LOADSELECTIONS(OBJ, SELECTIONS) returns a cell array of the same
%   size as SELECTIONS, with the data of each selection as load_mat_style
%   returns it. SELECTIONS is a cell array with one cell array of
%   MATLAB-style subscripts per selection.
%
%   A selection of a numeric dataset with one subscript per dimension,
%   each ':' or a contiguous ascending range, is read as one hyperslab.
%   All such selections are read with the file and dataset opened once.
%   Other selections are read with load_mat_style.

    arguments
        obj
        selections cell
    end

    data = cell(size(selections));
    dataDimensions = obj.dims;

    fileId = H5F.open(obj.Filename);
    datasetId = H5D.open(fileId, obj.DatasetPath);
    isNumeric = isNumericDataset(datasetId);

    isHyperslab = false(size(selections));
    for iSelection = 1:numel(selections)
        isHyperslab(iSelection) = isNumeric ...
            && isHyperslabSelection(selections{iSelection}, dataDimensions);
    end

    if any(isHyperslab)
        spaceId = H5D.get_space(datasetId);
        for iSelection = 1:numel(selections)
            if ~isHyperslab(iSelection)
                continue
            end
            [start, count] = getHyperslab(selections{iSelection}, dataDimensions);
            % HDF5 orders dimensions opposite to MATLAB and counts from 0.
            H5S.select_hyperslab(spaceId, 'H5S_SELECT_SET', ...
                fliplr(start - 1), [], fliplr(count), []);
            memorySpaceId = H5S.create_simple(numel(count), fliplr(count), []);
            block = H5D.read(datasetId, 'H5ML_DEFAULT', memorySpaceId, spaceId, 'H5P_DEFAULT');
            H5S.close(memorySpaceId);
            data{iSelection} = reshape(block, count);
        end
        H5S.close(spaceId);
    end
    H5D.close(datasetId);
    H5F.close(fileId);

    for iSelection = 1:numel(selections)
        if ~isHyperslab(iSelection)
            data{iSelection} = obj.load_mat_style(selections{iSelection}{:});
        end
    end
end

function tf = isNumericDataset(datasetId)
% Integer and floating-point values need no conversion after the read;
% load_mat_style converts every other class.
    typeId = H5D.get_type(datasetId);
    typeClass = H5T.get_class(typeId);
    H5T.close(typeId);
    tf = typeClass == H5ML.get_constant_value('H5T_INTEGER') ...
        || typeClass == H5ML.get_constant_value('H5T_FLOAT');
end

function tf = isHyperslabSelection(selection, dataDimensions)
% A single subscript is a linear index, which load_mat_style reads as a
% point selection and shapes by its own rules, so it is not a hyperslab.
    tf = iscell(selection) && numel(dataDimensions) > 1 ...
        && numel(selection) == numel(dataDimensions) && all(dataDimensions > 0);
    for iDimension = 1:numel(selection)
        if ~tf
            return
        end
        subscript = selection{iDimension};
        if ischar(subscript) || isstring(subscript)
            tf = strcmp(subscript, ':');
        else
            tf = isnumeric(subscript) && isvector(subscript) ...
                && subscript(1) >= 1 && subscript(1) == floor(subscript(1)) ...
                && subscript(end) <= dataDimensions(iDimension) ...
                && all(diff(subscript) == 1);
        end
    end
end

function [start, count] = getHyperslab(selection, dataDimensions)
% First element (1-based) and number of elements in each dimension.
    start = ones(size(dataDimensions));
    count = dataDimensions;
    for iDimension = 1:numel(selection)
        subscript = selection{iDimension};
        if ~ischar(subscript) && ~isstring(subscript)
            start(iDimension) = subscript(1);
            count(iDimension) = numel(subscript);
        end
    end
end
