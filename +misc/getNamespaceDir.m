function namespaceDir = getNamespaceDir(varargin)
    % Get the location of the namespaces directory regardless of current MATLAB working directory.
    % started: 2020.07.02 [11:20:30]
    % inputs
        %
    % outputs
        %

    % changelog
        % 2020.07.02 [11:24:10] - Function created and added warning if namespaces directory could not be found. - Biafra Ahanonu.
        % 2020.12.29 [13:40:00] - Function simplified to use local namespace directory first.
    % TODO
        %
        
    localNamespace = fullfile(misc.getWorkspace(), 'namespaces');
    rootNamespace = fullfile(misc.getMatnwbDir(), 'namespaces');
    if 7 == exist(localNamespace, 'dir')
        namespaceDir = localNamespace;
    elseif 7 == exist(rootNamespace, 'dir')
        namespaceDir = rootNamespace;
    else
        warning('Directory "namespaces" not found.');
        namespaceDir = '';
    end
end