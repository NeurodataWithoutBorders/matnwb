classdef Filter < uint64
    %FILTER Compression filter registered to HDF5
    % as defined by (https://portal.hdfgroup.org/display/support/Filters)
    % Submit an issue if we're missing one you wish to use!
    
    enumeration
        SZ3 (32024)
        CBF (32006)
        SZ (32017)
        BLOSC (32001)
        BZIP2 (307)
        JPEG_LS (32012)
        VBZ (32020)
        JPEG_XR (32007)
        CCSDS_123 (32011)
        FCIDECOMP (32018)
        BitShuffle (32008)
        FPZip (32014)
        B3D (32016)
        JPEG (32019)
        LPC_Rice (32010)
        LZ4 (32004)
        LZF (32000)
        LZO (305)
        MAFISC (32002)
        ZFP (32013)
        ZStandard (32015)
        APAX (32005)
        Snappy (32003)
        SPDP (32009)
        BitGroom (32022)
        GBR (32023) % Granular BitRound
        FAPEC (32021)
    end
end

