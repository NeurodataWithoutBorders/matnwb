classdef HasQuantity
% HasQuantity - Provide methods for parsing quantity specification value
    
    % properties
    %     QuantityKey = 'quantity'
    % end
    
    methods (Static, Access = protected)
        function isRequired = isRequired(source)
            if isKey(source, 'quantity')
                quantity = source('quantity');
                file.interface.HasQuantity.validateQuantity(quantity)

                if ischar(quantity)
                    switch quantity
                        case {'?', 'zero_or_one'}
                            isRequired = false;
                        case {'*', 'zero_or_many'}
                            isRequired = false;
                        case {'+', 'one_or_many'}
                            isRequired = true;
                    end
                elseif isnumeric(quantity)
                    isRequired = quantity >= 1;
                end
            else
                isRequired = true; % Default
            end
        end

        function isScalar = isScalar(source)
            if isKey(source, 'quantity')
                quantity = source('quantity');
                file.interface.HasQuantity.validateQuantity(quantity)

                if ischar(quantity)
                    switch quantity
                        case {'?', 'zero_or_one'}
                            isScalar = true;
                        case {'*', 'zero_or_many'}
                            isScalar = false;
                        case {'+', 'one_or_many'}
                            isScalar = false;
                    end
                elseif isnumeric(quantity)
                    if quantity == 1
                        isScalar = true;
                    else
                        isScalar = false;
                    end
                end
            else
                isScalar = true; % Default
            end
        end
    end

    methods (Static, Access = private)
        function validateQuantity(quantity)
        % validateQuantity - Validate quantity specification value 
            if ischar(quantity)
                validQuantities = [ ...
                    "?", "zero_or_one", ...
                    "*", "zero_or_many", ...
                    "+", "one_or_many" ...
                    ];
                if ~any(strcmp(validQuantities, quantity))
                    validQuantitiesStr = strjoin("  " + validQuantities, newline);
                    ME = MException('NWB:Schema:UnsupportedQuantity', ...
                        ['Quantity is "%s", but expected quantity to be one of the ' ...
                        'following values:\n%s\n'], quantity, validQuantitiesStr);
                    throwAsCaller(ME)
                end

            elseif isnumeric(quantity)
                assert( mod(quantity,1) == 0 && quantity > 0, ...
                    'NWB:Schema:UnsupportedQuantity', ...
                    'Expected quantity to positive integer')
            else
                ME = MException('NWB:Schema:UnsupportedQuantity', ...
                    'Expected quantity to be text or numeric.');
                throwAsCaller(ME)
            end
        end
    end
end
