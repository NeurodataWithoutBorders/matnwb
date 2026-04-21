function result = readObjectArray(zarrPath)
% readObjectArray - Read NWB object-dtype Zarr arrays via python-zarr.

    try
        zarrModule = py.importlib.import_module('zarr');
    catch
        error("NWB:Zarr2:PythonZarrUnavailable", ...
            "Python package `zarr` is required to read NWB object-dtype Zarr arrays.")
    end

    zarrArray = zarrModule.open_array(char(zarrPath), pyargs('mode', 'r'));
    getItem = py.getattr(zarrArray, '__getitem__');
    rawData = getItem(py.slice(py.None));
    result = convertPythonValue(rawData.tolist());
end

function value = convertPythonValue(pyValue)
    if isa(pyValue, 'py.list') || isa(pyValue, 'py.tuple')
        pythonItems = cell(pyValue);
        value = cell(size(pythonItems));
        for iItem = 1:numel(pythonItems)
            value{iItem} = convertPythonValue(pythonItems{iItem});
        end
    elseif isa(pyValue, 'py.bytes')
        value = char(pyValue.decode('utf-8'));
    elseif isa(pyValue, 'py.str')
        value = char(pyValue);
    elseif isa(pyValue, 'py.hdmf_zarr.utils.ZarrReference')
        value = jsondecode(strrep(char(pyValue), '''', '"'));
    elseif isa(pyValue, 'py.dict')
        jsonModule = py.importlib.import_module('json');
        value = jsondecode(char(jsonModule.dumps(pyValue)));
    elseif isa(pyValue, 'py.NoneType')
        value = [];
    elseif isa(pyValue, 'py.bool')
        value = logical(pyValue);
    else
        try
            value = double(pyValue);
        catch
            try
                value = char(pyValue);
            catch ME
                error("NWB:Zarr2:UnsupportedObjectValue", ...
                    "Unable to convert python value `%s`: %s", class(pyValue), ME.message)
            end
        end
    end
end
