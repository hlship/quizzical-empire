var express = require('express');

var exec = require('child_process').exec;

var app = express.createServer(express.logger());

app.get('/', function(request, response) {

  console.log("Received request for /");

  exec("ls -laR", function (error, stdout, stdin) {
      response.writeHeader(200, { "Content-Type": "text/plain" });
      response.write(stdout);
      response.end();
  });

});

var port = process.env.PORT || 8080;
app.listen(port, function() {
  console.log("Listening on " + port);
});
