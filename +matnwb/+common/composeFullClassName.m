function fullClassName = composeFullClassName(namespaceName, neurodataType)
    arguments
        namespaceName (:, 1) string
        neurodataType (:, 1) string
    end

    if contains(namespaceName, '-')
        % MATLAB does not support "-" in namespace names
        namespaceName = strrep(namespaceName, '-', '_');
    end

    for i = 1:numel(namespaceName)
        namespaceName{i} = misc.str2validName(namespaceName{i});
        neurodataType{i} = misc.str2validName(neurodataType{i});
    end

    fullClassName = compose("types.%s.%s", namespaceName, neurodataType);
    fullClassName = transpose(fullClassName); % Return as row vector
end
