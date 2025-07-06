function fullClassName = composeFullClassName(namespaceName, neurodataType)
    arguments
        namespaceName (:, 1) string
        neurodataType (:, 1) string
    end

    fullClassName = compose("types.%s.%s", namespaceName, neurodataType);
    fullClassName = transpose(fullClassName); % Return as row vector
end
