classdef DataPipe < types.untyped.DataStub
    %DATAPIPE Special form of Datastub that allows for appending.
    
    properties (SetAccess = private)
        current_offset = 0;
        max_size;
    end
    
    methods % lifecycle
        function obj = DataPipe(filename, path, max_size)
            obj = obj@types.untyped.DataStub(filename, path);
            
            obj.max_size = max_size;
        end
    end
    
    methods
        function append(obj, data)
            fid = H5F.open(obj.filename);
            try
                did = H5D.open(fid, obj.path);
            catch ME
                PLIST = 'H5P_DEFAULT';
                [tid, sid, data] = io.mapData2H5(fid, data, 'forceArray');
                H5S.set_extent_simple(sid,...
                    numel(obj.max_size),...
                    fliplr(size(data)),...
                    fliplr(obj.max_size));
                did = H5D.create(fid, obj.path, tid, sid, PLIST, PLIST, PLIST);
                
                H5T.close(tid);
                H5S.close(sid);
            end
            
            sid = H5D.get_space(did);
            H5S.select_none(sid);
            H5S.select_hyperslab(sid,...
                'H5S_SELECT_SET', obj.current_offset, [], numel(data), []);
            
            [mem_tid, mem_sid, data] = io.mapData2H5(fid, data, 'forceArray');
            
            H5D.write(did, mem_tid, mem_sid, sid, 'H5P_DEFAULT', data);
            H5S.close(sid);
            H5D.close(did);
            H5F.close(fid);
            
            obj.current_offset = obj.current_offset + numel(data);
        end
    end
end

