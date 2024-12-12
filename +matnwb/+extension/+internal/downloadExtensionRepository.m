function [wasDownloaded, repoTargetFolder] = downloadExtensionRepository(...
    repositoryUrl, repoTargetFolder, extensionName)
% downloadExtensionRepository - Download the repository (source) for an extension
%
%   The metadata for a neurodata extension only provides the url to the
%   repository containing the extension, not the full download url. This
%   function tries to download a zipped version of the repository from
%   either the "main" or the "master" branch.
%
%   Works for repositories located on GitHub or GitLab
%
%   As of Dec. 2024, this approach works for all registered extensions

    arguments
        repositoryUrl (1,1) string
        repoTargetFolder (1,1) string
        extensionName (1,1) string
    end

    import matnwb.extension.internal.downloadZippedRepo
    
    defaultBranchNames = ["main", "master"];

    wasDownloaded = false;
    for i = 1:2
        try
            branchName = defaultBranchNames(i);
            downloadUrl = buildRepoDownloadUrl(repositoryUrl, branchName, extensionName);
            repoTargetFolder = downloadZippedRepo(downloadUrl, repoTargetFolder);
            wasDownloaded = true;
            break
        catch ME
            if strcmp(ME.identifier, 'MATLAB:webservices:HTTP404StatusCodeError')
                continue
            else
                rethrow(ME)
            end
        end
    end
end

function downloadUrl = buildRepoDownloadUrl(repositoryUrl, branchName, extensionName)
% buildRepoDownloadUrl - Build a download URL for a given repository and branch
    arguments
        repositoryUrl (1,1) string
        branchName (1,1) string
        extensionName (1,1) string
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
        error('NWB:InstallExtension:UnknownRepository', ...
            ['Extension "%s" is located in an unsupported repository ', ...
             '/ source location. \nPlease create an issue on MatNWB''s ', ...
             'github page'], extensionName)
    end
end
