function requirement = parseRequirement(requirementText)
% parseRequirement - Parse a Python package requirement.
%
%   requirement = matnwb.extension.internal.parseRequirement(requirementText)
%   parses one entry of the "requires_dist" list in the PyPI metadata of a
%   package, for example "ndx-ophys-devices==0.2.0" or
%   "ndx-events (>=0.4.0)". It returns a struct with the fields:
%
%   - Name (string) - The package name, normalized to lowercase with
%     hyphens, as PyPI compares names.
%   - Specifiers (string array) - Version conditions, such as ">=0.4.0".
%   - IsOptional (logical) - True when the requirement applies only to an
%     optional feature (an "extra" marker such as `; extra == "dev"`).

    arguments
        requirementText (1,1) string
    end

    % An environment marker follows a semicolon.
    requirementParts = split(requirementText, ";");
    requirementSpec = strip(requirementParts(1));
    if numel(requirementParts) > 1
        markerText = strjoin(requirementParts(2:end), ";");
    else
        markerText = "";
    end

    nameText = regexp(requirementSpec, "^[A-Za-z0-9._-]+", "match", "once");
    assert(~ismissing(nameText) && strlength(nameText) > 0, ...
        "NWB:InstallExtension:InvalidRequirement", ...
        "Could not read a package name from the requirement ""%s"".", requirementText)

    specifierText = extractAfter(requirementSpec, strlength(nameText));
    % Remove a list of extras, such as "[dev]", and the parentheses of the older form.
    specifierText = regexprep(specifierText, "^\s*\[[^\]]*\]", "");
    specifierText = erase(specifierText, ["(", ")"]);
    specifiers = strip(split(specifierText, ","));
    specifiers = reshape(specifiers(strlength(specifiers) > 0), 1, []);

    requirement = struct( ...
        "Name", normalizeName(nameText), ...
        "Specifiers", replace(specifiers, " ", ""), ...
        "IsOptional", contains(markerText, "extra"));
end

function name = normalizeName(name)
% normalizeName - Normalize a package name as PyPI does (PEP 503).
    name = lower(regexprep(name, "[-_.]+", "-"));
end
