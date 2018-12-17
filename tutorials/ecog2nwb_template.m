EXTERNAL_SUBJ = true;
generateExtension('/Users/bendichter/dev/nwbext_ecog/nwbext_ecog/ecog.namespace.yaml')

%% cortical surfaces
cortical_surfaces = types.ecog.CorticalSurfaces;

surface_names = {'a', 'b', 'c'};
for i = 1:length(surface_names)
    surface_name = surface_names{i};
    vertices = randn(3, 10);
    faces = randi([0, 9], 3, 15); % faces use 0-index
    surf = types.ecog.Surface('faces', faces, 'vertices', vertices);
    cortical_surfaces.surface.set(surface_name, surf);
end

subject = types.ecog.ECoGSubject('cortical_surfaces', cortical_surfaces);

if EXTERNAL_SUBJ
    date = datetime(1900, 1, 1, 1, 0, 0);
    session_start_time = datetime(date, 'Format', 'yyyy-MM-dd''T''HH:mm:SSZZ',...
        'TimeZone', 'local');
    subject_nwb = nwbfile('session_description', 'a test NWB File', ...
        'identifier', 'S1', ...
        'session_start_time', session_start_time, ...
        'subject', subject);

    nwbExport(nwb, 'S1.nwbaux')
    
    subject = types.untyped.ExternalLink('S1.nwbaux','/general/subject');
end

% the rest is similar to ecephys tutorial



