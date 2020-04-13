classdef BoundPipe < types.untyped.datapipe.Pipe
    %BOUND Represents a Bound DataPipe which must point to a valid file.
    
    properties (SetAccess = private)
        filename; % OS path to the HDF5 file.
        path; % HDF5 path to the chunked dataset.
        
        filters = types.untyped.datapipe.Filter.empty;
    end
    
    methods % lifecycle
        function obj = BoundPipe(filename, path)
            fid = H5F.open(filename);
            did = H5D.open(fid, path);
            pid = H5D.get_create_plist(did);
            tid = H5D.get_type(did);
            
            sid = H5D.get_space(did);
            [numdims, h5_dims, h5_maxdims] = H5S.get_simple_extent_dims(sid);
            H5S.close(sid);
            
            current_size = fliplr(h5_dims);
            max_size = fliplr(h5_maxdims);
            if 1 == numdims
                current_size = [current_size 1];
                max_size = [max_size 1];
            end
            [~, h5_chunk_dims] = H5P.get_chunk(pid);
            
            deflate_filter = H5ML.get_constant_value('H5Z_FILTER_DEFLATE');
            level = -1;
            for i = 0:(H5P.get_nfilters(pid) - 1)
                [filter, ~, cd_values, ~, ~] = H5P.get_filter(pid, i);
                if filter == deflate_filter
                    level = cd_values;
                    break;
                end
            end
            
            obj.maxSize = max_size;
            obj.axis = axis;
            obj.offset = current_size(obj.axis);
            obj.chunkSize = fliplr(h5_chunk_dims);
            obj.compressionLevel = level;
            obj.dataType = io.getMatType(tid);
            obj.filename = filename;
            obj.path = path;
            
            H5T.close(tid);
            H5P.close(pid);
            H5D.close(did);
            H5F.close(fid);
        end
    end
    
    methods
        function refs = export(~, ~, ~, refs)
            return;
        end
    end
end