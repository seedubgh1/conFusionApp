function func(prop, val) {
  var jsonStr = '{"'+prop+'":'+val+'}'
  return JSON.parse(jsonStr);
};

var testa = func("init",99);

console.log(testa);
