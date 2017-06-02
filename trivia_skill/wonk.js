var https = require('https');
//https://opentdb.com/api.php?amount=5
var questions = {};

function cb_func(data){
  questions = data;
};

function callHTTPGet1(callback) {

    return https.get({
        host: 'opentdb.com',
        path: '/api.php?amount=5'
    }, function(response) {
        // Continuously update stream with data
        var body = '';
        response.on('data', function(d) {
            body += d;
        });
        response.on('end', function() {

            // Data reception is done, do whatever with it!
            var parsed = JSON.parse(body);
            console.log(parsed);
            callback({
                email: parsed.email,
                password: parsed.pass
            });
        });
        questions
    });

};

callHTTPGet1(cb_func);

console.log(questions);
