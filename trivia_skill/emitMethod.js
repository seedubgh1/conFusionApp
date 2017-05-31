var request = require("request");
var EventEmitter = require("events").EventEmitter;
var body = new EventEmitter();
var questions = {};


request('https://opentdb.com/api.php?amount=5&category=11', function(error, response, data) {
    body.data = data;
    body.emit('update');
});

body.on('update', function () {
    //console.log(body.data); // HOORAY! THIS WORKS!
	questions = body.data;
});

console.log(questions);