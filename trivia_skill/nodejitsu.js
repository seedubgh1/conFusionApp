var https = require('https');

var options = {
  host: 'opentdb.com',
  path: '/api.php?amount=5&category=11'
};

var  bdy = '';

callback = function(response) {
  var str = '';

  //another chunk of data has been recieved, so append it to `str`
  response.on('data', function (chunk) {
    str += chunk;
  });

  //the whole response has been recieved, so we just print it out here
  response.on('end', function () {
    //console.log(str);
	response.write(bdy);
  });
}

https.request(options, callback).end();

console.log('bdy: ',bdy);