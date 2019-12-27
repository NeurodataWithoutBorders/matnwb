classdef Hyperslab
    %HYPERSLAB Representation of a hyperslab selection in HDF5.  Note that these values
    % are assumed to be HDF5 compliant (zero-indexed row-major).  Use the static methods
    % to convert from MATLAB indices to Hyperslab indices.
    
    methods (Static)
        function Hyperslabs = from_indices(indices, arraySize)
            indices = sort(indices(:));
        end
        
        function Hyperslabs = from_mask(logicalMask)
            h5.space.Hyperslab.from_indices(find(logicalMask), size(logicalMask));
        end
        
        function Hyperslabs = from_h5(h5_format)
            %FROM_H5 the h5 format consists of a cell array of start and end indices.
            % we will convert these to an equivalent array of hyperslabs.
        end
    end
    
    properties
        start;
        stride;
        count;
    end
end

