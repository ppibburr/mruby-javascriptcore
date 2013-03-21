function baz() {
  var ary = new Array();
  
  ary[0] = rubyProperty;
  ary[1] = rubyAdd(1,2);
  ary[3] = rubyFunctionWithClosure(ary,function(array) {
    array.push(4);
  });
  
  return ary;
}
baz();
