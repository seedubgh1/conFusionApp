var request = require("request");
var quest = {};

request("https://opentdb.com/api.php?amount=5", function(error, response, data) {
    body = data;
    quest = JSON.parse(body);
});
console.log(quest);
