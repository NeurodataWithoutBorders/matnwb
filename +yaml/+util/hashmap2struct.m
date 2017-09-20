% Convert Java HashMap to MATLAB struct
function s = hashmap2struct(hm)
  validateattributes(hm, {'java.util.HashMap'}, {});
  s = struct();
  ks = cell(hm.keySet().toArray());
  for i=1:length(ks)
    key = ks{i};
    s.(key) = hm.get(key);
  end
end