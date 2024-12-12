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
    import matnwb.extension.internal.buildRepoDownloadUrl

    defaultBranchNames = ["main", "master"];

    wasDownloaded = false;
    for i = 1:2
        try
            branchName = defaultBranchNames(i);
            downloadUrl = buildRepoDownloadUrl(repositoryUrl, branchName);
            repoTargetFolder = downloadZippedRepo(downloadUrl, repoTargetFolder);
            wasDownloaded = true;
            break
        catch ME
            if strcmp(ME.identifier, 'MATLAB:webservices:HTTP404StatusCodeError')
                continue
            elseif strcmp(ME.identifier, 'NWB:BuildRepoDownloadUrl:UnsupportedRepository')
                error('NWB:InstallExtension:UnsupportedRepository', ...
                    ['Extension "%s" is located in an unsupported repository ', ...
                     '/ source location. \nPlease create an issue on MatNWB''s ', ...
                     'github page'], extensionName)
            else
                rethrow(ME)
            end
        end
    end
end
