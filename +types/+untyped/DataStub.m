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
        
        function sid = get_space(obj)
            fid = H5F.open(obj.filename);
            did = H5D.open(fid, obj.path);
            sid = H5D.get_space(did);
            H5D.close(did);
            H5F.close(fid);
        end
        
        function d = dims(obj)
            fid = H5F.open(obj.filename);
            did = H5D.open(fid, obj.path);
            sid = H5D.get_space(did);
            [~, d, ~] = H5S.get_simple_extent_dims(sid);
            %to MATLAB array size format
            if numel(d) == 1
                d = [d 1];
            end
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
        
        %can be called without arg, with H5ML.id, or (dims, offset, stride)
        function data = load(obj, varargin)
            fid = H5F.open(obj.filename);
            did = H5D.open(fid, obj.path);
            %             tid = H5D.get_type(did);
            %             info = h5info(obj.filename, obj.path);
            
            switch length(varargin)
                case 0
                    sid = 'H5S_ALL';
                    fsid = 'H5S_ALL';
                case 1
                    sid = varargin{1};
                    fsid = sid;
                otherwise
                    dims = varargin{1};
                    offset = varargin{2};
                    stride = varargin{3};
                    fsid = H5D.get_space(did);
                    H5S.select_hyperslab(fsid, 'H5S_SELECT_SET',...
                        offset,...
                        stride,...
                        [],... %everything is essentially one block
                        dims);
                    
                    if all(dims == 1)
                        sid = H5S.create('H5S_SCALAR');
                    elseif any(dims == 0)
                        sid = H5S.create('H5S_NULL');
                    else
                        % set Inf to unlimited
                        dims(isinf(dims)) = ...
                            H5ML.get_constant_value('H5S_UNLIMITED');
                        sid = H5S.create_simple(numel(dims), dims, dims);
                    end
            end
            
            data = H5D.read(did, 'H5ML_DEFAULT', sid, fsid, 'H5P_DEFAULT');
            if isstruct(data)
                data = io.parseCompound(did, data);
            end
            if ~isempty(varargin) && ~isa(varargin{1}, 'H5ML.id')
                %don't close a provided space id.
                H5S.close(sid);
            end
            H5D.close(did);
            H5F.close(fid);
        end
        
        function refs = export(obj, fid, fullpath, refs)
            %Check for compound data type refs
            srcfid = H5F.open(obj.filename);
            srcdid = H5D.open(srcfid, obj.path);
            srctid = H5D.get_type(srcdid);
            srcsid = H5D.get_space(srcdid);
            ref_i = false;
            if H5T.get_class(srctid) == H5ML.get_constant_value('H5T_COMPOUND')
                ncol = H5T.get_nmembers(srctid);
                ref_i = false(1, ncol);
                subtids = cell(1, ncol);
                for i = 1:ncol
                    subclass = H5T.get_member_class(srctid, i-1);
                    subtid = H5T.get_member_type(srctid, i-1);
                    subtids{i} = subtid;
                    refTypeConst = H5ML.get_constant_value('H5T_REFERENCE');
                    ref_i(i) = subclass == refTypeConst;
                end
            end
            
            %manually load the data struct
            if any(ref_i)
                %This requires loading the entire table.
                %Due to this HDF5 library's inability to delete/update
                %dataset data, this is unfortunately required.
                [data, tid] = obj.processCompound(...
                    ref_i, subtids(ref_i), srcdid, fid);
                did = H5D.create(fid, fullpath, tid, srcsid, 'H5P_DEFAULT');
                H5D.write(did, tid, srcsid, srcsid, 'H5P_DEFAULT', data);
                H5D.close(did);
            else
                %copy data over and return destination
                ocpl = H5P.create('H5P_OBJECT_COPY');
                lcpl = H5P.create('H5P_LINK_CREATE');
                H5O.copy(srcfid, obj.path, fid, fullpath, ocpl, lcpl);
                H5P.close(ocpl);
                H5P.close(lcpl);
            end
            H5T.close(srctid);
            H5S.close(srcsid);
            H5D.close(srcdid);
            H5F.close(srcfid);
        end
    end
    
    methods(Access=private)
        function [data, tid] = processCompound(obj, ref_i, reftids, srcdid,...
                destfid)
            %ripped from io.parseCompound because struct2table is
            %incredibly slow
            %In the future, might use a more efficient intermediate type
            %strings are also a little wonky but only because they're
            %nested
            data = H5D.read(srcdid);
            
            propnames = fieldnames(data);
            %convert ref types so io.getBaseType recognizes it
            refPropNames = propnames(ref_i);
            for i=1:length(refPropNames)
                rpname = refPropNames{i};
                refdata = data.(rpname);
                reflist = cell(size(refdata, 2), 1);
                for j=1:size(refdata, 2)
                    r = refdata(:,j);
                    reflist{j} = io.parseReference(srcdid, reftids{i}, r);
                end
                data.(rpname) = reflist;
            end
            
            %get typesize, compound tids, and data manipulation
            typesizes = zeros(size(propnames));
            subtid = cell(size(propnames));
            for i=1:length(propnames)
                name = propnames{i};
                prop = data.(name);
                if iscell(prop) && ~iscellstr(prop)
                    %references are also stored in cell arrays so we want
                    %to identify those
                    typestr = class(prop{1});
                else
                    typestr = class(prop);
                end
                subtid{i} = io.getBaseType(typestr, prop .');
                typesizes(i) = H5T.get_size(subtid{i});
                if iscellstr(prop)
                    %convert cell str to transposed char array
                    data.(name) = cell2mat(io.padCellStr(prop)) .';
                elseif iscell(prop) &&...
                        (isa(prop{1}, 'types.untyped.ObjectView') ||...
                        isa(prop{1}, 'types.untyped.RegionView'))
                    %convert references to raw using destination
                    refarr = uint8(zeros(typesizes(i), length(prop)));
                    for j=1:length(prop)
                        refarr(:, j) = io.getRefData(destfid, prop{j});
                    end
                    data.(name) = refarr;
                end
            end
            
            %construct type
            tid = H5T.create('H5T_COMPOUND', sum(typesizes));
            offset = 0;
            for i=1:length(propnames)
                H5T.insert(tid, propnames{i}, offset, subtid{i});
                offset = offset + typesizes(i);
            end
            H5T.pack(tid);
        end
    end
end