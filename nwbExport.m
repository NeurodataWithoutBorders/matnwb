function nwbExport(nwb, filenames)
    %NWBEXPORT Writes an NWB file.
    %  nwbRead(nwb,filename) Writes the nwb object to a file at filename.
    %
    %  Example:
    %    % Generate Matlab code for the NWB objects from the core schema.
    %    % This only needs to be done once.
    %    generateCore('schema\core\nwb.namespace.yaml');
    %    % Create some fake fata and write
    %    nwb = NwbFile;
    %    nwb.session_start_time = datetime('now');
    %    nwb.identifier = 'EMPTY';
    %    nwb.session_description = 'empty test file';
    %    nwbExport(nwb, 'empty.nwb');
    %
    %  See also GENERATECORE, GENERATEEXTENSION, NWBFILE, NWBREAD
    validateattributes(nwb, {'NwbFile'}, {'nonempty'}, 'nwbExport', 'nwb', 1);
    validateattributes(filenames, {'cell', 'string', 'char'}, {'nonempty'}, 'nwbExport', 'filenames', 2);
    if isstring(filenames)
        filenames = convertStringsToChars(filenames);
    end
    if iscell(filenames)
        for iName = 1:length(filenames)
            name = filenames{iName};
            validateattributes(name, {'string', 'char'}, {'scalartext', 'nonempty'} ...
                , 'nwbExport', 'filenames', 2);
            filenames{iName} = char(name);
        end
    end
    if ~isscalar(nwb)
        assert(~ischar(filenames) && length(filenames) == length(nwb), ...
            'NwbFile and filename array dimensions must match.');
    end
    
    for iFiles = 1:length(nwb)
        if iscellstr(filenames)
            filename = filenames{iFiles};
        else
            filename = filenames;
        end
        
        nwb(iFiles).export(filename);
    end
end
