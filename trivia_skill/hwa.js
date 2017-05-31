var https = require('https');
//https://opentdb.com/api.php?amount=5
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
            callback({
                email: parsed.email,
                password: parsed.pass
            });
        });
    });

};
//====================
function callHTTPGet2(cb) {

    https.get({
        host: 'opentdb.com',
        path: '/api.php?amount=5'
    }, function(res) {
        // explicitly treat incoming data as utf8 (avoids issues with multi-byte chars)
        res.setEncoding('utf8');

        // incrementally capture the incoming response body
        var body = '';
        res.on('data', function(d) {
            body += d;
        });

        // do whatever we want with the response once it's done
        res.on('end', function() {
            try {
                var parsed = JSON.parse(body);
            } catch (err) {
                console.error('Unable to parse response as JSON', err);
                return cb(err);
            }

            // pass the relevant data back to the callback
            cb(null, {
                email: parsed.email,
                password: parsed.pass
            });
        });
    }).on('error', function(err) {
        // handle errors with the request itself
        console.error('Error with the request:', err.message);
        cb(err);
    });

};
//=============================
var concat = require('concat-stream');

function callHTTPGet3(callback) {

    return https.get({
        host: 'opentdb.com',
        path: '/api.php?amount=5'
    }, function(response) {
        response.pipe(concat(function(body) {
            // Data reception is done, do whatever with it!
            var parsed = JSON.parse(body);
			console.log(parsed);
            callback(parsed);
        }))
    });

};

//var tgt = '';
function set_tgt(data){
	var tgt;
	tgt = data;
};

callHTTPGet3(set_tgt);