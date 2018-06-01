classdef DataStub
    properties(SetAccess=private)
        filename;
        path;
    end
    
    methods
        
        function obj = DataStub(filename, path)
            obj.filename = filename;
            obj.path = path;
        end
        
        function d = dims(obj)
            fid = H5F.open(obj.filename);
            did = H5D.open(fid, obj.path);
            sid = H5D.get_space(did);
            [~, d, ~] = H5S.get_simple_extent_dims(sid);
            H5S.close(sid);
            H5D.close(did);
            H5F.close(fid);
        end
        
        function rank = ndims(obj)
            fid = H5F.open(obj.filename);
            did = H5D.open(fid, obj.path);
            sid = H5D.get_space(did);
            rank = H5S.get_simple_extent_ndims(sid);
            H5S.close(sid);
            H5D.close(did);
            H5F.close(fid);
        end
        
        function count = numel(obj)
            fid = H5F.open(obj.filename);
            did = H5D.open(fid, obj.path);
            sid = H5D.get_space(did);
            count = H5S.get_simple_extent_npoints(sid);
            H5S.close(sid);
            H5D.close(did);
            H5F.close(fid);
        end
        
        function data = load(obj, offset, dims, stride)
            if nargin < 2
                data = h5read(obj.filename, obj.path);
                return;
            end
            
            if nargin < 4
                stride = [];
            end
            
            if ~isnumeric(offset) || ~isnumeric(dims)
                error('Argument(s): `offset` and `dims` must be numeric');
            end
            
            if ~isnumeric(stride)
                error('Optional Argument(s): `stride` must be numeric.');
            end
            
            fid = H5F.open(obj.filename);
            did = H5D.open(fid, obj.path);
            
            mem_sid = H5S.create_simple(length(dims), fliplr(dims), []);
            file_sid = H5D.get_space(did);
            H5S.select_hyperslab(file_sid, 'H5S_SELECT_SET', offset, stride, [], dims);
            data = H5D.read(did, 'H5ML_DEFAULT', mem_sid, file_sid, 'H5P_DEFAULT');
            H5S.close(mem_sid);
            H5S.close(file_sid);
            H5D.close(did);
            H5F.close(fid);
        end
        
        function refs = export(obj, fid, fullpath, refs)
            %copy data over and return destination
            dest_id = H5F.open(obj.filename);
            
            ocpl = H5P.create('H5P_OBJECT_COPY');
            lcpl = H5P.create('H5P_LINK_CREATE');
            H5O.copy(dest_id, obj.path, fid, fullpath, ocpl, lcpl);
            H5P.close(ocpl);
            H5P.close(lcpl);
            H5F.close(dest_id);
        end
    end
end