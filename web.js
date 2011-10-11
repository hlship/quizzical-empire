var app = require('express').createServer();

app.get('/', function(req, res){
  res.writeHead(200, {'Content-Type': 'text/html'});
  res.end("<html><body><h1>Hello from NodeJS</h1></body></html>");
  res.send('hello world');
});

app.listen(8080, "127.0.0.1");