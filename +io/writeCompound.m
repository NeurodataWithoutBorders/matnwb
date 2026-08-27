function writeCompound(fid, fullpath, data, varargin)
% writeCompound - Write structured data to an HDF5 compound dataset.
% 
%   io.writeCompound(fid, fullpath, data, varargin) converts data (in table, 
%   struct, or containers.Map format) into a scalar struct, optimizes it for 
%   HDF5 storage, and writes it to an HDF5 compound dataset specified by fid 
%   and fullpath.
%
%   Inputs:
%     fid       - File identifier for an open HDF5 file.
%     fullpath  - Full path within the HDF5 file where data will be stored.
%     data      - Data to write, provided as a table, struct, or containers.Map.
%     varargin  - Additional optional arguments.
%
%   Functionality:
%     - Converts input data into a scalar struct, rearranging fields and types as needed.
%     - Detects data types, sizes, and handles compound HDF5 type creation.
%     - Optimizes data for HDF5 by transposing column vectors and converting logicals.
%     - Manages references to external data objects, regions, or untyped views.
%     - Attempts to extend or overwrite existing datasets if a compound dataset at 
%       the specified path already exists.
%
%   Notes:
%     - If `fullpath` already exists in the HDF5 file, the function tries to adjust 
%       dimensions if the dataset is chunked, and issues a warning if resizing is not allowed.
%
%   Example:
%     io.writeCompound(fid, '/group/dataset', data);

    forceArray = any(strcmp('forceArray', varargin));
    forceMatrix = any(strcmp('forceMatrix', varargin));

    % Normalize the input to a scalar struct holding one column per field,
    % taking the row count from the input.
    if istable(data)
        numRows = height(data);
        data = tableToColumnStruct(data);
    elseif isstruct(data) && ~isscalar(data)
        numRows = numel(data);
        data = structArrayToColumnStruct(data);
    else
        if isa(data, 'containers.Map')
            data = mapToColumnStruct(data);
        end
        numRows = scalarStructNumRows(data);
    end

    names = fieldnames(data);
    if isempty(names)
        error('NWB:WriteCompound:NoFields', ...
            ['Cannot write the compound dataset "%s" because the data has no ' ...
            'fields, and a compound type needs at least one member. Provide a ' ...
            'table with at least one column, a struct with at least one field, ' ...
            'or a containers.Map with at least one key.'], fullpath)
    end

    %check for references and construct tid.
    classes = cell(length(names), 1);
    tids = cell(size(classes));
    sizes = zeros(size(classes));
    for i=1:length(names)
        val = data.(names{i});
        if iscell(val) && ~iscellstr(val)
            data.(names{i}) = [val{:}];
            val = val{1};
        end

        classes{i} = class(val);
        tids{i} = io.getBaseType(classes{i});
        sizes(i) = H5T.get_size(tids{i});
    end

    tid = H5T.create('H5T_COMPOUND', sum(sizes));
    for i=1:length(names)
        %insert columns into compound type
        H5T.insert(tid, names{i}, sum(sizes(1:i-1)), tids{i});
    end
    %close custom type ids (errors if char base type)
    isH5ml = tids(cellfun('isclass', tids, 'H5ML.id'));
    for i=1:length(isH5ml)
        H5T.close(isH5ml{i});
    end
    %optimizes for type size
    H5T.pack(tid);

    isReferenceClass = strcmp(classes, 'types.untyped.ObjectView') |...
        strcmp(classes, 'types.untyped.RegionView');

    if verLessThan('matlab', '9.8') % Matlab < 2020a
    % For MATLAB releases earlier than R2020a, character vectors must be
    % wrapped in a cell array, otherwise the write operation will fail with
    % the following error id "MATLAB:imagesci:hdf5dataset:badInputClass"
    % and message "The class of input data must be cellstring instead of char
    % when the HDF5 class is VARIABLE LENGTH H5T_STRING."
        for i = 1:length(names)
            val = data.(names{i});
            if ischar(val)
                data.(names{i}) = {data.(names{i})};
            end
        end
    end
    
    % convert logical values
    boolNames = names(strcmp(classes, 'logical'));
    for iField = 1:length(boolNames)
        data.(boolNames{iField}) = int8(data.(boolNames{iField}));
    end

    %transpose numeric column arrays to row arrays
    % reference and str arrays are handled below
    transposeNames = names(~isReferenceClass);
    for i=1:length(transposeNames)
        nm = transposeNames{i};
        if iscolumn(data.(nm))
            data.(nm) = data.(nm) .';
        end
    end

    %attempt to convert raw reference information
    referenceNames = names(isReferenceClass);
    for i=1:length(referenceNames)
        data.(referenceNames{i}) = io.getRefData(fid, data.(referenceNames{i}));
    end

    try
        if numRows == 1 && ~(forceArray || forceMatrix)
            sid = H5S.create('H5S_SCALAR');
        else
            sid = H5S.create_simple(1, numRows, []);
        end
        did = H5D.create(fid, fullpath, tid, sid, 'H5P_DEFAULT');
    catch ME
        if contains(ME.message, 'name already exists')
            did = H5D.open(fid, fullpath);
            create_plist = H5D.get_create_plist(did);
            edit_sid = H5D.get_space(did);
            [~, edit_dims, ~] = H5S.get_simple_extent_dims(edit_sid);
            layout = H5P.get_layout(create_plist);
            is_chunked = layout == H5ML.get_constant_value('H5D_CHUNKED');
            is_same_dims = all(edit_dims == numRows);

            if ~is_same_dims
                if is_chunked
                    H5D.set_extent(did, dims);
                else
                    warning('NWB:WriteCompund:ContinuousCompoundResize', ...
                        'Attempted to change size of continuous compound `%s`.  Skipping.', ...
                        fullpath);
                    H5D.close(did);
                    H5S.close(sid);
                    return
                end
            end
            H5P.close(create_plist);
            H5S.close(edit_sid);
        else
            rethrow(ME);
        end
    end
    H5D.write(did, tid, sid, sid, 'H5P_DEFAULT', data);
    H5D.close(did);
    H5S.close(sid);
end

function s = tableToColumnStruct(data)
% tableToColumnStruct - Convert a table to a scalar struct of columns.
    if height(data) == 0
        s = zeroRowTableToColumnStruct(data);
    else
        s = structArrayToColumnStruct(table2struct(data));
    end
end

function s = zeroRowTableToColumnStruct(data)
% zeroRowTableToColumnStruct - Convert a table with no rows to a scalar struct
% of empty columns.
%
% Each compound member takes its type from the class of its column, and
% table2struct loses those classes for a zero-row table, so the columns are
% read off the table directly. Numeric and logical columns keep their class.
% Every other column is carried as an empty cellstr, giving it the variable
% length string member type, which is the type a text column gets for a table
% with rows. Classes that cannot be typed from an empty value, such as object
% references, therefore also write as strings.
    s = struct();
    variableNames = data.Properties.VariableNames;
    for iVariable = 1:numel(variableNames)
        column = data{:, iVariable};
        if ~isnumeric(column) && ~islogical(column)
            column = cell(0, 1);
        end
        s.(variableNames{iVariable}) = column;
    end
end

function s = structArrayToColumnStruct(data)
% structArrayToColumnStruct - Gather a struct array into a scalar struct whose
% fields each hold that field's column of values.
    s = struct();
    names = fieldnames(data);
    for iName = 1:numel(names)
        s.(names{iName}) = {data.(names{iName})};
    end
end

function s = mapToColumnStruct(data)
% mapToColumnStruct - Convert a containers.Map to a scalar struct of columns.
    s = struct();
    names = keys(data);
    vals = values(data, names);
    for iName = 1:numel(names)
        s.(misc.str2validName(names{iName})) = vals{iName};
    end
end

function numrows = scalarStructNumRows(data)
% scalarStructNumRows - Number of rows a scalar struct describes.
%
% A scalar struct holds either a single row of values or one column per field.
% The two are told apart by the first field: text is a single value, anything
% else is a column whose length is the row count.
    names = fieldnames(data);
    if isempty(names)
        numrows = 0;
        return
    end
    firstColumn = data.(names{1});
    if ischar(firstColumn)
        numrows = 1;
    else
        numrows = length(firstColumn);
    end
end
