classdef HasSubObjects < h5.interface.HasId
    %HASSUBOBJECTS This class can contain Links, Datasets, and Groups
    
    methods
        function Link = add_link(obj, varargin)
            Link = h5.Link.create(obj, varargin{:});
        end
        
        function delete_link(obj, name)
            assert(ischar(name), 'NWB:H5:Group:InvalidArgument',...
                'name must be a string.')
            H5L.delete(obj.get_id(), name, 'H5P_DEFAULT');
        end
        
        function add_dataset(obj, varargin)
            h5.Dataset.create(obj, varargin{:});
        end
        
        function add_compound(obj, varargin)
            h5.CompoundDataset.create(obj, varargin{:});
        end
        
        function add_group(obj, varargin)
            h5.Group.create(obj, varargin{:});
        end
        
        function SubObjects = get_all_subobjects(obj)
            subNames = {};
            [~, subNames] = H5O.visit(obj.get_id(),...
                'H5_INDEX_NAME', 'H5_ITER_NATIVE',...
                @retrieve_names,...
                subNames);
            
            SubObjects = h5.interface.IsObject.empty(length(subNames), 0);
            for i = 1:length(subNames)
                SubObjects(i) = obj.get_subobject(subNames{i});
            end
            
            function [status, subNames] = retrieve_names(~, name, subNames)
                status = 0;
                if strcmp(name, '.')
                    % skip self
                    return;
                end
                subNames{end+1} = name;
            end
        end
        
        function SubObj = get_subobject(obj, name)
            obj_lapl = 'H5P_DEFAULT';
            oid = H5O.open(obj.get_id(), name, obj_lapl);
            obj_type = H5I.get_type(oid);
            switch obj_type
                case h5.const.Identifiers.Dataset.constant
                    SubObj = h5.Dataset(name, oid);
                case h5.const.Identifiers.Group.constant
                    SubObj = h5.Group(name, oid);
                case h5.const.Identifiers.Link.constant
                    % the H5L api works with (loc_id, name) pairs to identify
                    % links instead of the standard object_id.
                    SubObj = read_link(obj.get_id(), name);
                    H5O.close(oid);
                otherwise
                    error('NWB:H5:HasSubObjects:GetSubObjects:UnexpectedObject',...
                        'Got unexpected type %d', obj_type);
            end
            
            function Link = read_link(id, name)
                link_lapl = 'H5P_DEFAULT';
                LinkInfo = H5L.get_info(id, name, link_lapl);
                switch LinkInfo.type
                    case h5.const.LinkType.Soft.const
                        path = H5L.get_val(id, name, link_lapl);
                        Link = types.untyped.SoftLink(path);
                    case h5.const.LinkType.External.const
                        % linkValues is a cell array tuple (filename, path).
                        linkValues = H5L.get_val(id, name, link_lapl);
                        Link = types.untyped.ExternalLink(linkValues{:});
                    otherwise
                        error(...
                            'NWB:H5:HasSubObjects:GetSubObjects:UnsupportedLinkType',...
                            'Unsupported Link type found %d', LinkInfo.type);
                end
            end
        end
    end
end