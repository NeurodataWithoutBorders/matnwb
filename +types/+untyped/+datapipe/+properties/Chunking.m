classdef Chunking < types.untyped.datapipe.Property
    %CHUNKING Dataset chunking
    
    methods (Static)
        function obj = fromDcpl(dcpl)
            import types.untyped.datapipe.properties.Chunking;
            [~, h5_chunk_dims] = H5P.get_chunk(dcpl);
            if matnwb.preference.shouldFlipDimensions()
                chunk_dims = fliplr(h5_chunk_dims);
            else
                chunk_dims = h5_chunk_dims;
            end
            obj = Chunking(chunk_dims);
        end
    end
    
    properties
        chunkSize;
    end
    
    methods % lifecycle
        function obj = Chunking(chunkSize)
            obj.chunkSize = chunkSize;
        end
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
    
    %% Properties
    methods (Static)
        function tf = isInDcpl(dcpl)
            tf = H5ML.get_constant_value('H5D_CHUNKED') == H5P.get_layout(dcpl);
        end
    end
    
    methods
        function addTo(obj, dcpl)
            if matnwb.preference.shouldFlipDimensions()
                h5_chunk_size = fliplr(obj.chunkSize);
            else
                h5_chunk_size = obj.chunkSize;
            end
            H5P.set_chunk(dcpl, h5_chunk_size);
        end
    end
end

