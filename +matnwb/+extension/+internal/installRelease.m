function installRelease(packageName, version, saveDir, downloadFolder, dependencyChain)
% installRelease - Install a release of an extension from PyPI, dependencies first.
%
%   matnwb.extension.internal.installRelease(packageName, version, saveDir, downloadFolder)
%   installs the given release of an extension package and the NWB
%   extensions it requires. A required extension is installed first,
%   unless the version already generated in saveDir meets the requirement.
%   The version installed for a requirement is the release it pins with
%   ==, or the latest release that meets its conditions.
%
%   Only requirements on NWB extensions (packages named "ndx-...") are
%   installed. Requirements on Python packages such as pynwb, and
%   requirements of optional features, are skipped.
%
%   The version of an installed extension is read from its namespace,
%   which extensions publish with the same version as the package.

    arguments
        packageName (1,1) string
        version (1,1) string
        saveDir (1,1) string
        downloadFolder (1,1) string
        dependencyChain (1,:) string = strings(1, 0)
    end

    import matnwb.extension.internal.getPypiRelease
    import matnwb.extension.internal.downloadRelease
    import matnwb.extension.internal.parseRequirement

    release = getPypiRelease(packageName, version);
    dependencyChain = [dependencyChain, release.Name];

    for requirementText = release.Requirements
        requirement = parseRequirement(requirementText);
        if requirement.IsOptional || ~startsWith(requirement.Name, "ndx-")
            continue
        end
        if ismember(requirement.Name, dependencyChain)
            % The extensions require each other; the one higher in the chain is being installed.
            continue
        end
        installRequirement(requirement, release, saveDir, downloadFolder, dependencyChain)
    end

    namespaceFilePath = downloadRelease(release, downloadFolder);
    generateExtension(namespaceFilePath, 'savedir', saveDir);
    fprintf("Installed extension ""%s"" version %s.\n", release.Name, release.Version)
end

function installRequirement(requirement, parentRelease, saveDir, downloadFolder, dependencyChain)
    import matnwb.extension.internal.isVersionSatisfied

    installedVersion = readInstalledVersion(requirement.Name, saveDir);
    if installedVersion ~= "" && isVersionSatisfied(installedVersion, requirement.Specifiers)
        return
    end

    requiredVersion = resolveRequiredVersion(requirement, parentRelease);
    if installedVersion ~= ""
        message = sprintf("Replacing extension ""%s"" version %s with version %s, which ""%s"" %s requires.", ...
            requirement.Name, installedVersion, requiredVersion, parentRelease.Name, parentRelease.Version);
        dependentNames = listInstalledDependents(requirement.Name, saveDir);
        dependentNames = setdiff(dependentNames, parentRelease.Name, "stable");
        if ~isempty(dependentNames)
            message = message + sprintf(" These installed extensions were generated with version %s " + ...
                "and may not work with version %s: %s.", ...
                installedVersion, requiredVersion, strjoin(dependentNames, ", "));
        end
        fprintf("%s\n", message)
    end
    matnwb.extension.internal.installRelease( ...
        requirement.Name, requiredVersion, saveDir, downloadFolder, dependencyChain)
end

function dependentNames = listInstalledDependents(namespaceName, saveDir)
% listInstalledDependents - List the generated namespaces that depend on a namespace.
    dependentNames = strings(1, 0);
    allNamespaceInfo = spec.loadCache("savedir", saveDir);
    for namespaceInfo = reshape(allNamespaceInfo, 1, [])
        if ismember(namespaceName, string(namespaceInfo.dependencies))
            dependentNames(end+1) = string(namespaceInfo.name); %#ok<AGROW>
        end
    end
end

function version = readInstalledVersion(namespaceName, saveDir)
% readInstalledVersion - Read the version of a generated namespace, or "" if there is none.
    namespaceInfo = spec.loadCache(namespaceName, "savedir", saveDir);
    if isempty(namespaceInfo)
        version = "";
    else
        version = string(namespaceInfo.version);
    end
end

function version = resolveRequiredVersion(requirement, parentRelease)
% resolveRequiredVersion - Find the latest release that meets a requirement.
    import matnwb.extension.internal.isVersionSatisfied

    availableVersions = matnwb.extension.internal.listPypiVersions(requirement.Name);
    isCandidate = arrayfun(@(v) isVersionSatisfied(v, requirement.Specifiers), availableVersions);
    candidates = availableVersions(isCandidate);
    if isempty(candidates)
        error("NWB:InstallExtension:DependencyVersionNotFound", ...
            "Extension ""%s"" %s requires ""%s"" %s, but no release of ""%s"" on PyPI meets this.", ...
            parentRelease.Name, parentRelease.Version, requirement.Name, ...
            strjoin(requirement.Specifiers, ","), requirement.Name)
    end

    version = candidates(1);
    for candidate = candidates(2:end)
        if isVersionSatisfied(candidate, ">" + version)
            version = candidate;
        end
    end
end
