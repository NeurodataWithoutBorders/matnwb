function tf = isVersionSatisfied(version, specifiers)
% isVersionSatisfied - Check a version against Python version specifiers.
%
%   tf = matnwb.extension.internal.isVersionSatisfied(version, specifiers)
%   returns true when version, such as "0.3.1", meets every specifier in
%   specifiers, such as [">=0.3.1", "<0.5"]. An empty specifiers array is
%   met by any version.
%
%   Supported operators: ==, ===, !=, >=, <=, >, < and ~=, and a trailing
%   ".*" with == and !=. Versions are compared by their numeric release
%   segments; a version with a pre-release or other suffix meets only an
%   exact == or === specifier.

    arguments
        version (1,1) string
        specifiers (1,:) string
    end

    tf = true;
    for specifier = specifiers
        parsed = regexp(specifier, "^(?<operator>===|==|!=|~=|>=|<=|>|<)(?<target>\S+)$", ...
            "names", "once");
        assert(~isempty(parsed), "NWB:InstallExtension:InvalidVersionSpecifier", ...
            "Could not read the version specifier ""%s"".", specifier)
        if ~isSpecifierMet(version, parsed.operator, parsed.target)
            tf = false;
            return
        end
    end
end

function tf = isSpecifierMet(version, operator, target)
    if operator == "===" || (operator == "==" && ~endsWith(target, ".*"))
        tf = (version == target) || (isReleaseVersion(version) && isReleaseVersion(target) ...
            && compareVersions(version, target) == 0);
        return
    end
    if ~isReleaseVersion(version)
        tf = false;
        return
    end

    switch operator
        case "=="
            tf = isPrefixMatch(version, extractBefore(target, strlength(target) - 1));
        case "!="
            if endsWith(target, ".*")
                tf = ~isPrefixMatch(version, extractBefore(target, strlength(target) - 1));
            else
                tf = compareVersions(version, target) ~= 0;
            end
        case ">="
            tf = compareVersions(version, target) >= 0;
        case "<="
            tf = compareVersions(version, target) <= 0;
        case ">"
            tf = compareVersions(version, target) > 0;
        case "<"
            tf = compareVersions(version, target) < 0;
        case "~="
            % ~=1.4.2 means >=1.4.2 and ==1.4.*
            targetParts = split(target, ".");
            prefix = strjoin(targetParts(1:end-1), ".");
            tf = compareVersions(version, target) >= 0 && isPrefixMatch(version, prefix);
        otherwise
            % The pattern in isVersionSatisfied admits only the operators above.
            tf = false;
    end
end

function tf = isReleaseVersion(version)
    tf = ~isempty(regexp(version, "^\d+(\.\d+)*$", "once"));
end

function tf = isPrefixMatch(version, prefix)
    versionParts = str2double(split(version, "."));
    prefixParts = str2double(split(prefix, "."));
    paddedVersion = [versionParts; zeros(max(0, numel(prefixParts) - numel(versionParts)), 1)];
    tf = isequal(paddedVersion(1:numel(prefixParts)), prefixParts);
end

function result = compareVersions(versionA, versionB)
% compareVersions - Return -1, 0 or 1 as versionA is lower, equal or higher.
    partsA = str2double(split(versionA, "."));
    partsB = str2double(split(versionB, "."));
    partCount = max(numel(partsA), numel(partsB));
    partsA(end+1:partCount) = 0;
    partsB(end+1:partCount) = 0;
    differingIndex = find(partsA ~= partsB, 1);
    if isempty(differingIndex)
        result = 0;
    else
        result = sign(partsA(differingIndex) - partsB(differingIndex));
    end
end
