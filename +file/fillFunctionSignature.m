function entryText = fillFunctionSignature(name, props, namespace, superClassProps)
% fillFunctionSignature - Create the function signature entry for a constructor.
%
%   entryText = file.fillFunctionSignature(name, props, namespace, superClassProps)
%   returns the text of one entry for a functionSignatures.json file, in
%   the form "types.<namespace>.<name>": {...}. The entry lists the
%   name-value arguments of the class constructor, so MATLAB can suggest
%   them while the user types.
%
%   The arguments are the properties of the class and its superclasses, as
%   listed in the constructor help text. Read-only properties are left out,
%   because the constructor does not set them. Properties that hold a set
%   of typed members are left out too: their members are passed under the
%   member's own name, which the schema does not fix.

    allProps = file.internal.mergeProps(props, superClassProps);
    propNames = allProps.keys();

    inputs = struct("name", {}, "kind", {}, "purpose", {});
    for iProp = 1:numel(propNames)
        prop = allProps(propNames{iProp});
        if isReadOnly(prop) || holdsTypedSet(prop)
            continue
        end
        argument = struct( ...
            "name", file.internal.getMatlabPropertyName(propNames{iProp}), ...
            "kind", "namevalue", ...
            "purpose", getPurpose(prop));
        inputs(end+1) = argument; %#ok<AGROW>
    end

    fullClassName = namespace.getFullClassName(name);
    % A cell array encodes as a JSON array also when it has one element.
    signatureJson = jsonencode(struct("inputs", {num2cell(inputs)}), "PrettyPrint", true);
    entryText = sprintf('"%s": %s', fullClassName, signatureJson);
end

function tf = isReadOnly(prop)
    tf = (isa(prop, "file.Attribute") || isa(prop, "file.Dataset")) && prop.readonly;
end

function tf = holdsTypedSet(prop)
% holdsTypedSet - True for a property that the constructor initializes as a Set.
%
%   Matches the cases for which file.fillConstructor uses a Set as the default.

    isPluralSet = isa(prop, "file.interface.HasProps") && ~isscalar(prop);
    isGroupSet = ~isPluralSet && isa(prop, "file.Group") ...
        && (prop.hasAnonData || prop.hasAnonGroups || prop.isConstrainedSet);
    isDataSet = ~isPluralSet && isa(prop, "file.Dataset") && prop.isConstrainedSet;
    tf = isPluralSet || isGroupSet || isDataSet;
end

function purpose = getPurpose(prop)
% getPurpose - Get the schema doc of a property as a single line.
    purpose = "";
    if isprop(prop, "doc") && ~isempty(prop(1).doc)
        purpose = strjoin(split(strtrim(string(prop(1).doc))), " ");
    end
end
