function downloadUrl = buildRepoDownloadUrl(repositoryUrl, branchName)
% buildRepoDownloadUrl - Build a download URL for a given repository and branch
    arguments
        repositoryUrl (1,1) string
        branchName (1,1) string
    end

    if endsWith(repositoryUrl, '/')
        repositoryUrl = extractBefore(repositoryUrl, strlength(repositoryUrl));
    end

    if contains(repositoryUrl, 'github.com')
        downloadUrl = sprintf( '%s/archive/refs/heads/%s.zip', repositoryUrl, branchName );
    
    elseif contains(repositoryUrl, 'gitlab.com')
        repoPathSegments = strsplit(repositoryUrl, '/');
        repoName = repoPathSegments{end};
        downloadUrl = sprintf( '%s/-/archive/%s/%s-%s.zip', ...
            repositoryUrl, branchName, repoName, branchName);
    
    else
        error('NWB:BuildRepoDownloadUrl:UnsupportedRepository', ...
            'Expected repository URL to point to a GitHub or a GitLab repository')
    end
end
