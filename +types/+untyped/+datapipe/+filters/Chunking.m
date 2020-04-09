classdef Chunking < types.untyped.datapipe.Filter
    %CHUNKING Dataset chunking
    
    properties
        chunkSize;
    end
    
    methods % set/get
        function set.chunkSize(obj, val)
            errorId = 'NWB:Untyped:DataPipe:Filters:Chunking:InvalidChunkSize';
            assert(isnumeric(val) && all(val > 0),...
                errorId,...
                'Chunk Size must a non-zero size of the same rank as maxSize');
            obj.chunkSize = val;
        end
    end
    
    methods % Filter
        function addTo(obj, dcpl)
            H5P.set_chunk(dcpl, fliplr(obj.chunkSize));
        end
        
        function name = getName(obj)
            name = 'chunking';
        end
    end
end

