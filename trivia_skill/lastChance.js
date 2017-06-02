// var request = require("request");
// var quest = {};
//
// request("https://opentdb.com/api.php?amount=5", function(error, response, data) {
//     body = data;
//     quest = JSON.parse(body);
// });
// console.log(quest);
// var request = require("request");
// var body = {};
//
//
// request("https://opentdb.com/api.php?amount=5", function(error, response, data) {
//     body = data;
//     console.log(body);
// });
//
// console.log(body);
var request = require("request");
var EventEmitter = require("events").EventEmitter;
var body = new EventEmitter();
var bdy = {};


request("https://opentdb.com/api.php?amount=5", function(error, response, data) {
    body.data = data;
    body.emit('update');
});

body.on('update', function () {
    console.log('on upd: ',body.data); // HOORAY! THIS WORKS!
});
bdy = body.on;
console.log('bdy: ',bdy);
