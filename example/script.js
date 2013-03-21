function() {
  var ary = Array.new();
  
  ary[0] = rubyProperty;
  ary[1] = rubyAdd(1,2);
  ary[2] = rubyFunctionWithClosure(ary,function(array) {
    array.push(4);
  });
  
  return ary;
}();
