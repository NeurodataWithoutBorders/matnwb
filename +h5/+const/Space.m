classdef Space < h5.interface.IsConstant
    %SPACE Space Size Constants.
    
    enumeration
        Unlimited('H5S_UNLIMITED'); % A space extent setting which implies that the data space is chunked.
        AllSpace('H5S_ALL');  % A unique Space Id constant that seems to be used as a wildcard.
    end
end

