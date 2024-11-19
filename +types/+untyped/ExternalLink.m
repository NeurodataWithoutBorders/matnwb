classdef ExternalLink < handle
    properties
        filename;
        path;
    end
    
    methods
        function obj = ExternalLink(filename, path)
            validateattributes(filename, {'char', 'string'}, {'scalartext'} ...
                , 'types.untyped.ExternalLink', 'filename', 1);
            validateattributes(path, {'char', 'string'}, {'scalartext'} ...
                , 'types.untyped.ExternalLink', 'path', 2);
            obj.filename = char(filename);
            obj.path = char(path);
        end
        
        function data = deref(obj)
            data = cell(size(obj));
            for i = 1:numel(obj)
                data{i} = scalar_deref(obj(i));
            end
            
            if isscalar(data)
                data = data{1};
            end
            
            function data = scalar_deref(Link)
                % if path is valid hdf5 path, then returns either a Nwb Object, DataStub, or Link Object
                % otherwise errors, probably.
                assert(ischar(Link.filename), 'expecting filename to be a char array.');
                assert(isfile(Link.filename), '%s does not exist.', Link.filename);
                
                fid = H5F.open(Link.filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
                LinkedInfo = h5info(Link.filename, Link.path);
                loc = [Link.filename Link.path];
                
                if isfield(LinkedInfo, 'Attributes')
                    attr_names = {LinkedInfo.Attributes.Name};
                    is_typed = any(strcmp(attr_names, 'neurodata_type')...
                        | strcmp(attr_names, 'namespace'));
                else
                    is_typed = false;
                end
                
                is_dataset = all(isfield(LinkedInfo, {...
                    'FillValue',...
                    'ChunkSize',...
                    'Dataspace',...
                    'Datatype',...
                    'Filters',...
                    'Attributes'}));
                is_group = all(isfield(LinkedInfo, {...
                    'Groups',...
                    'Datasets',...
                    'Datatypes',...
                    'Links',...
                    'Attributes'}));
                is_link = all(isfield(LinkedInfo, {...
                    'Type',...
                    'Value'
                    }));
                assert(is_dataset || is_group || is_link,...
                    'NWB:ExternalLink:UnknownHdfType',...
                    'Unsupported HDF externally linked type (not a group, dataset, or link!');
                assert(1 == sum([is_dataset is_group is_link]),...
                    'NWB:ExternalLink:AmbiguousHdfType',...
                    'Externally linked HDF type is ambiguous! (cannot discern between group, dataset, or link!)');
                
                if is_dataset
                    % typed objects and references are handled by
                    % io.parseDataset
                    if is_typed || strcmp(LinkedInfo.Datatype.Class, 'H5T_REFERENCE')
                        data = io.parseDataset(Link.filename, LinkedInfo, Link.path);
                    else
                        data = types.untyped.DataStub(Link.filename, Link.path);
                    end
                elseif is_group
                    assert(is_typed,...
                        'NWB:ExternalLink:UntypedGroup',...
                        ['MatNWB cannot return a non-typed group. Please return the parent '...
                        'typed object that contains `%s`'], loc);
                    data = io.parseGroup(Link.filename, LinkedInfo);
                else % link
                    data = deref_link(fid, Link);
                end
                H5F.close(fid);
            end
            
            function data = deref_link(fid, Link)
                linfo = H5L.get_info(fid, Link.path, 'H5P_DEFAULT');
                is_external = linfo.type == H5ML.get_constant_value('H5L_TYPE_EXTERNAL');
                is_soft = linfo.type == H5ML.get_constant_value('H5L_TYPE_SOFT');
                assert(is_external || is_soft,...
                    ['Unsupported link type in %s, with name %s.  '...
                    'Links must be external or soft.'],...
                    Link.filename, Link.path);
                
                link_val = H5L.get_val(fid, Link.path, 'H5P_DEFAULT');
                if is_external
                    data = types.untyped.ExternalLink(link_val{:});
                else
                    data = types.untyped.SoftLink(link_val{:});
                end
            end
        end
        
        function refs = export(obj, fid, fullpath, refs)
            plist = 'H5P_DEFAULT';
            if H5L.exists(fid, fullpath, plist)
                H5L.delete(fid, fullpath, plist);
            end
            H5L.create_external(obj.filename, obj.path, fid, fullpath, plist, plist);
        end
    end
end