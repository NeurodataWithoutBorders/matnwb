function datasetValue = processDatasetInfo(obj, datasetInfo, datasetPath)
    
% ZARR

    % Todo:
    % - Reference
    % - Not simple: String
    % - Simple: datapipe or datastub

    datatype = datasetInfo.Datatype;
    dataspace = datasetInfo.Dataspace;

    % HDF5-specific logic
    %fid = H5F.open(obj.Filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
    %did = H5D.open(fid, datasetPath);
    
    % loading h5t references are required
    % unfortunately also a bottleneck
    if isObjectReference(datasetInfo)
        %datasetValue = io.internal.zarr.parseReference(); %TODO
        datasetValue = 'reference placeholder';
    % elseif isScalarDataset(datasetInfo)
    %     datasetValue = zarrread(datasetInfo.Name);
    else
        datasetPath = io.internal.pathjoin(obj.Filename, datasetPath);

        zInfo = zarrinfo(datasetPath);

        if ischar(zInfo.zarr_dtype)
            zInfo.zarr_dtype = string(zInfo.zarr_dtype);
        end

        if numel(zInfo.zarr_dtype) > 1 % compound
            % Todo: Mathworks package can not read this.Issue made
            %keyboard
            datasetValue = zarrread(datasetPath);%, "Fieldnames",["x", "y"]);
            %warning('Compound datasets not supported yet')
                % names = {zInfo.zarr_dtype.name};
                % nvPairs = [names; repmat({{}}, 1, numel(names))];
                % datasetValue = struct(nvPairs{:});

        elseif strcmp(zInfo.dtype, '|O') % zInfo.zarr_dtype == "bytes" || 
            datasetValue = read_zarr_object(datasetPath);
        else
            datasetValue = zarrread(datasetPath);
            if ismatrix(datasetValue)
                datasetValue = datasetValue';
            else
                % MatNWB dimensions are permuted
                datasetValue = permute(datasetValue, ndims(datasetValue):-1:1);
            end
        end
        %datasetValue = 0;
    end
end

function getDataType()

end

function tf = isObjectReference(datasetInfo)
    tf = false;
    if ~isempty(datasetInfo.Attributes)
        isZarrDtypeAttr = strcmp({datasetInfo.Attributes.Name}, 'zarr_dtype');
        if any(isZarrDtypeAttr)
            zarrDtypeValue = datasetInfo.Attributes(isZarrDtypeAttr).Value;
            tf = strcmp(zarrDtypeValue, 'object');
        end
    end
end

function tf = isScalarDataset(datasetInfo)
    tf = false;
    if ~isempty(datasetInfo.Attributes)
        isZarrDtypeAttr = strcmp({datasetInfo.Attributes.Name}, 'zarr_dtype');
        if any(isZarrDtypeAttr)
            zarrDtypeValue = datasetInfo.Attributes(isZarrDtypeAttr).Value;
            tf = strcmp(zarrDtypeValue, 'scalar');
        end
    end
end