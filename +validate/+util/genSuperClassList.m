% given meta.class object, generates cell string array of superclasses until
% types.untyped.MetaClass is reached (MetaClass not included in the list)
function scl = genSuperClassList(mc)
  curr = mc;
  scl = {};
  while ~strcmp(curr.Name, 'types.untyped.MetaClass')
    scl{length(scl)+1} = curr.Name;
    curr = curr.SuperclassList;
  end
end