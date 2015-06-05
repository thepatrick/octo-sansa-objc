var octo = require('octo-sansa');

var server = octo.createServer();

server.on('connected', function(client) {

  console.log('client connected!');

  client.ask('who are you', {}, function(err, response) {
    console.log('Client said: ', err, response);
    client.tell('this is a tell', {});
  });

  client.on('client ask', function(args, callback) {
    console.log('client asked', args);
    callback(undefined, args);
  });

});

server.listen(10301, function() {
  console.log('Listening on 10301');
});
