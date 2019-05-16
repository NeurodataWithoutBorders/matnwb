function nwbExport(nwb, filename)
%NWBEXPORT Writes an NWB file.
%  nwbRead(nwb,filename) Writes the nwb object to a file at filename.
%
%  Example:
%    % Generate Matlab code for the NWB objects from the core schema.
%    % This only needs to be done once.
%    generateCore('schema\core\nwb.namespace.yaml');
%    % Create some fake fata and write
%    nwb = nwbfile;
%    nwb.session_start_time = datetime('now');
%    nwb.identifier = 'EMPTY';
%    nwb.session_description = 'empty test file';
%    nwbExport(nwb, 'empty.nwb');
%
%  See also GENERATECORE, GENERATEEXTENSION, NWBFILE, NWBREAD
validateattributes(nwb, {'nwbfile'}, {'nonempty'});
validateattributes(filename, {'cell', 'string', 'char'}, {'nonempty'});
if iscell(filename)
    assert(iscellstr(filename), 'filename cell array must consist of strings');
end
if ~isscalar(nwb)
    assert(~ischar(filename) && length(filename) == length(nwb), ...
        'nwbfile and filename array dimensions must match.');
end

for i=1:length(nwb)
    if iscellstr(filename)
        fn = filename{i};
    elseif isstring(filename)
        fn = filename(i);
    else
        fn = filename;
    end
    export(nwb(i), fn);
end
end
