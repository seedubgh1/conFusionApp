var unirest = require('unirest');
//var Request = unirest.get('http://mockbin.com/request');

questions = {};

unirest.get('https://opentdb.com/api.php?amount=5&category=11')
.headers({'Accept': 'application/json', 'Content-Type': 'application/json'})
.send({ "parameter": 23, "foo": "bar" })
.end(function (response) {
  console.log(response.body);
  questions = response.body;
});