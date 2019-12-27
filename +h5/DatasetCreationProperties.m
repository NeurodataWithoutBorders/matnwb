classdef DatasetCreationProperties
    %FILTER Dataset creation Property List Options
    
    methods
        function processArguments(obj, Dcpl, argument)
            assert(isa(Dcpl, 'h5.DatasetCreationPropertyList'),...
                'NWB:H5:DatasetCreationProperties:InvalidArgument',...
                'Dcpl should be a h5.DatasetCreationPropertyList');
            switch obj
                case h5.DatasetFilter.Chunking
                    chunkDimensions = argument;
                    H5P.set_chunk(Dcpl.get_id(), chunkDimensions);
                case h5.DatasetFilter.Deflate
                    deflateLevel = argument;
                    H5P.set_deflate(Dcpl.get_id(), deflateLevel);
            end
        end
    end
    
    enumeration
        Chunking;
        Deflate;
    end
end

