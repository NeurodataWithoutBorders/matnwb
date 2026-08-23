function exclusions = defaultParseExclusions()
% defaultParseExclusions - Names to skip when parsing a file into types.
%
%   exclusions = io.internal.defaultParseExclusions() returns a struct with
%   fields "attributes" and "groups" listing names that are consumed
%   internally by matnwb and must not be parsed into type properties:
%
%     - '.specloc' (attribute): reference to the embedded specifications
%       group, handled by io.spec functions.
%
%   Callers may append entries before parsing; for example, nwbRead adds
%   the resolved embedded specifications group to "groups", and
%   io.parseAttributes adds the type-defining attributes ('neurodata_type',
%   'namespace') after consuming them.

    exclusions = struct(...
        'attributes', {{'.specloc'}}, ...
        'groups', {{}});
end
