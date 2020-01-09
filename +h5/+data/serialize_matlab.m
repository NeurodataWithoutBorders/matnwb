function serData = serialize_matlab(data)
ERR_MSG_ID_STUB = 'NWB:H5:Type:SerializeMatlab:';

if isa(data, 'nwb.interface.Reference')
    warning([ERR_MSG_ID_STUB, 'SpecialSerializeRequired'],...
        ['RegionViews and ObjectViews need to call their own '...
        'serialize() functions with a provided h5.File as an argument.']);
end

switch class(data)
    case 'logical'
        %In HDF5, HBOOL is mapped to INT32LE
        serData = int32(data);
    case 'char'
        serData = {data};
    case 'cell'
        assert(iscellstr(data), [ERR_MSG_ID_STUB, 'NonCellString'],...
            ['For the sake of compatibility with HDF5 string arrays, all cells '...
            'passed to this method must be cell arrays of strings.']);
        serData = data;
    case 'datetime'
        serData = serialize_datetime(data);
    case {'struct', 'containers.Map', 'table'}
        serData = h5.compound.serialize_matlab(data);
    otherwise
        serData = data;
end
end

function serialized = serialize_datetime(dates)
serialized = cell(size(dates));

for i = 1:length(serialized)
    timestamp = dates(i);
    if isempty(timestamp.TimeZone)
        timestamp.TimeZone = 'local';
    end
    
    timestamp.Format = 'yyyy-MM-dd''T''HH:mm:ss.SSSSSSZZZZZ'; % ISO8601
    serialized{i} = char(timestamp);
end
end