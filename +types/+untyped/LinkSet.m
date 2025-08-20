classdef LinkSet < types.untyped.Set
    methods
        function refs = export(obj, fid, fullpath, refs)
            k = keys(obj.Map);
            val = values(obj.Map, k);
            for i=1:length(k)
                v = val{i};
                nm = k{i};
                propFullPath = [fullpath '/' nm];
                if startsWith(class(v), 'types.')
                    try
                        refs = v.export(fid, propFullPath, refs);
                    catch MECause
                        ME = MException('NWB:LinkSet:ExportFailed', ...
                            'Failed to export "%s" to path %s', nm, propFullPath);
                        ME = ME.addCause(MECause);
                        throw(ME)
                    end
                else
                    warning('Found type ("%s") which was not link.', class(v))
                end
            end
        end
                
        function obj = set(obj, name, val)
            if ischar(name)
                name = {name};
            end
            
            if ischar(val)
                val = {val};
            end
            cellExtract = iscell(val);
            
            assert(length(name) == length(val),...
                'number of property names should match number of vals on set.');
            for i=1:length(name)
                if cellExtract
                    elem = val{i};
                else
                    elem = val(i);
                end
                try
                    elem = obj.ValidationFcn(name{i}, elem);
                    obj.Map(name{i}) = elem;
                catch ME
                    warning('NWB:Set:FailedValidation' ...
                        , 'Failed to add key `%s` to Constrained Set with message:\n  %s' ...
                        , name{i}, ME.message);
                end
            end
        end
    end
end
