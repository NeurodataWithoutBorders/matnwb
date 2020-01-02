classdef Hyperslab
    %HYPERSLAB Representation of a hyperslab selection in HDF5.  Note that these values
    % are assumed to be HDF5 compliant (zero-indexed row-major).  Use the static methods
    % to convert from MATLAB indices to Hyperslab indices.
    
    methods (Static)
        function Hyperslab = from_h5(startCorner, endCorner)
            endBound = endCorner + 1;
            shape = endBound - startCorner;
            offset = startCorner - 1;
            Hyperslab = h5.space.Hyperslab(shape, 'offset', offset);
        end
    end
    
    properties
        offset = 0;
        shape = 0;
        stride = 0;
    end
    
    properties (SetAccess = private)
        bounds;
    end
    
    methods % lifecycle
        function obj = Hyperslab(shape, varargin)
            if nargin == 0
                return;
            end
            
            obj.shape = shape;
            validate_vector('shape', obj.shape);
            
            p = inputParser;
            p.addParameter('offset', zeros(size(shape)));
            p.addParameter('stride', zeros(size(shape)));
            p.parse(varargin{:});
            
            obj.offset = p.Results.offset;
            validate_vector('offset', obj.offset);
            assert(length(obj.offset) == length(obj.shape),...
                'NWB:H5:Hyperslab:InvalidArgument',...
                '`offset` must have the same rank as `shape`.');
            
            obj.stride = p.Results.stride;
            validate_vector('stride', obj.stride);
            assert(length(obj.stride) == length(obj.shape),...
                'NWB:H5:Hyperslab:InvalidArgument',...
                '`stride` must have the same rank as `shape`.');
            
            function validate_vector(name, vec)
                assert(isnumeric(vec) && all(vec >= 0) && isvector(vec),...
                'NWB:H5:Hyperslab:InvalidArgument',...
                '`%s` must be a non-negative numeric vector.', name);
            end
        end
    end
    
    methods % set/get
        function bounds = get.bounds(obj)
            bounds = (obj.stride + 1) * (obj.shape + obj.offset);
        end
    end
end

