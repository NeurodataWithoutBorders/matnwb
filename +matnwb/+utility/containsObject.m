function tf = containsObject(parent, target)
% containsObject - True if target is held anywhere below parent
%
% Syntax:
%  tf = matnwb.utility.containsObject(parent, target) returns true if target
%  is the value of a property of parent, or of anything parent contains.
%
% Input Arguments:
%  - parent -
%    The object to search below, for example an NwbFile. An object that
%    holds nothing, such as a dataset type, contains nothing.
%
%  - target (1,1) types.untyped.MetaClass -
%    The neurodata object to look for. Objects are matched by identity, so
%    a copy holding equal values is not a match.
%
% Output Arguments:
%  - tf (1,1) logical -
%    Whether parent contains target.
%
% This stops at the first match, unlike NwbFile.searchFor, which maps every
% object in the file before a membership test can begin. Properties, Set
% members and Anon values are visited, and only the kinds that hold other
% objects are descended into, so the traversal stays within the containment
% tree and cannot cycle.
%
% See also:
%   NwbFile.searchFor

    tf = false;
    if isa(parent, 'types.untyped.MetaClass')
        names = properties(parent);
        readValue = @(name) parent.(name);
    elseif isa(parent, 'types.untyped.Set')
        names = parent.keys();
        readValue = @(name) parent.get(name);
    elseif isa(parent, 'types.untyped.Anon')
        names = {parent.name};
        readValue = @(~) parent.value;
    else
        return
    end

    for iName = 1:numel(names)
        value = readValue(names{iName});
        if isa(value, 'types.untyped.MetaClass') && isscalar(value) ...
                && value == target
            tf = true;
            return
        end
        isContainer = isa(value, 'types.untyped.GroupClass') ...
            || isa(value, 'types.untyped.Set') ...
            || isa(value, 'types.untyped.Anon');
        % A Set held by a type with the HasUnnamedGroups mixin holds nothing
        % the loop above has not already seen, because the mixin exposes every
        % member as a dynamic property of the parent. An Anon is not exposed
        % that way, so it still has to be visited.
        isReachedAsProperty = isa(value, 'types.untyped.Set') ...
            && isa(parent, 'matnwb.mixin.HasUnnamedGroups');
        if isContainer && ~isReachedAsProperty
            tf = matnwb.utility.containsObject(value, target);
            if tf
                return
            end
        end
    end
end
