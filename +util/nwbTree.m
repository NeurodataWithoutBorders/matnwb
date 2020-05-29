function nwbTree(nwbfile)
    
f = uifigure('Name', 'NWB Tree');
tree = uitree(f,'Position',[20, 20 f.Position(3) - 20, f.Position(4) - 20]);
traverse_node(nwbfile, tree)

end


function out = traverse_node(node, tree_node)

if any(strcmp(superclasses(node), 'types.untyped.GroupClass'))
    pp = properties(node);
    for p = pp'
        if ~isempty(node.(p{1}))
            new_node = node.(p{1});
            if any(strcmp(superclasses(new_node), 'types.untyped.GroupClass'))
                new_tree_node = uitreenode(tree_node, 'Text', p{1});
                traverse_node(new_node, new_tree_node)
            elseif isa(new_node, 'types.untyped.Set')
                if new_node.Count
                    new_tree_node = uitreenode(tree_node, 'Text', p{1});
                    traverse_node(new_node, new_tree_node)
                end
            elseif isa(new_node, 'char')
                new_tree_node = uitreenode(tree_node, 'Text', [p{1} ': ' new_node]);
            else
                new_tree_node = uitreenode(tree_node, 'Text', p{1});
            end
        end
    end
elseif isa(node, 'types.untyped.Set')
    for key = node.keys()'
        new_tree_node = uitreenode(tree_node, 'Text', key{1});
        traverse_node(node.get(key), new_tree_node)
    end
elseif isa(node, 'char')
    uitreenode(tree_node, 'Text', node)
elseif isnumeric(node)
    uitreenode(tree_node, 'Text', num2str(node))
end

end