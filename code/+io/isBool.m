function tf = isBool(source)
%ISBOOL Checks a h5read Type struct if the defined type is a h5py boolean.
if isstruct(source)
    tf = isBoolFromTypeStruct(source);
elseif isa(source, 'H5ML.id')
    tf = isBoolFromTypeId(source);
else
    error('NWB:IO:IsBool:InvalidArgument',...
        ['isBool(source) must provide either a `h5info` Type struct or a ' ...
        'type id from low-level HDF5.']);
end
end

function tf = isBoolFromTypeStruct(Type)
tf = all([...
    strcmp('H5T_STD_I8LE', Type.Type),...
    2 == length(Type.Member),...
    all(strcmp({'FALSE', 'TRUE'}, sort({Type.Member.Name}))),...
    all([0,1] == sort([Type.Member.Value]))...
    ]);
end

function tf = isBoolFromTypeId(tid)
% we are more loose with the type id implementation.
% any enum with any backing type can be defined so long as member values
% 'FALSE' exists and is equal to 0, and 'TRUE' exists and is equal to 1.
if H5ML.get_constant_value('H5T_ENUM') ~= H5T.get_class(tid)
    tf = false;
    return;
end

try
    hasFalse = 0 == H5T.enum_valueof(tid, 'FALSE');
    hasTrue = 1 == H5T.enum_valueof(tid, 'TRUE');
    tf = hasFalse && hasTrue;
catch ME
    if ~contains(ME.message, 'string doesn''t exist in the enumeration type')
        % unknown error.
        rethrow(ME);
    end
    tf = false;
end
end