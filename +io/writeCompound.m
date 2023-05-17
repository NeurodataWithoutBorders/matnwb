function writeCompound(fid, fullpath, data, varargin)
    %convert to a struct
    if istable(data)
        data = table2struct(data);
    elseif isa(data, 'containers.Map')
        names = keys(data);
        vals = values(data, names);

        s = struct();
        for i=1:length(names)
            s.(misc.str2validName(names{i})) = vals{i};
        end
        data = s;
    end

    %convert to scalar struct
    names = fieldnames(data);
    if isempty(names)
        numrows = 0;
    elseif isscalar(data)
        if ischar(data.(names{1}))
            numrows = 1;
        else
            numrows = length(data.(names{1}));
        end
    else
        numrows = length(data);
        s = struct();
        for i=1:length(names)
            s.(names{i}) = {data.(names{i})};
        end
        data = s;
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

    % convert logical values
    boolNames = names(strcmp(classes, 'logical'));
    for iField = 1:length(boolNames)
        data.(boolNames{iField}) = strcmp('TRUE', data.(boolNames{iField}));
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
        sid = H5S.create_simple(1, numrows, []);
        did = H5D.create(fid, fullpath, tid, sid, 'H5P_DEFAULT');
    catch ME
        if contains(ME.message, 'name already exists')
            did = H5D.open(fid, fullpath);
            create_plist = H5D.get_create_plist(did);
            edit_sid = H5D.get_space(did);
            [~, edit_dims, ~] = H5S.get_simple_extent_dims(edit_sid);
            layout = H5P.get_layout(create_plist);
            is_chunked = layout == H5ML.get_constant_value('H5D_CHUNKED');
            is_same_dims = all(edit_dims == numrows);

            if ~is_same_dims
                if is_chunked
                    H5D.set_extent(did, dims);
                else
                    warning('Attempted to change size of continuous compound `%s`.  Skipping.',...
                        fullpath);
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