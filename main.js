// service to detect if an host in online
// http://www.downforeveryoneorjustme.com/doc.jquery.com
// shell function to use that service
/*
is_down() {

if wget -q -O - http://www.downforeveryoneorjustme.com/$1 | grep "looks down from here" > /dev/null
then
  return 1
else
  return 0
fi

}

# call it as:
# is_down example.com
*/


var
	fs = require('fs'),
	http = require("http"),
	io = require('socket.io'),
	server
;

server = http.createServer(function(req,res){

	var url = req.url;

	console.log( '[' + (new Date()).toString() + '] ' + req.socket.remoteAddress + ' ' + req.method + ' ' + url );

	// default go to the index.html
	(url == '/' ? url = '/index.html' : '');

	fs.readFile( __dirname + url, 'utf-8', function(err, data){
		if( err )
		{
			res.writeHead(404);
			res.end();
		}
		else
		{
			// res.writeHead(200,{"Content-Type": "text/html"});
			res.writeHead(200);
			res.end( data );
		}
	});

});
server.listen(8000);

var socket = io.listen(server, {log:false});
socket.on( 'connection', function(client){
	client.send('Hello from node, it\'s ' + (new Date()).toString() );
	console.log('client connect ' + client.sessionId );

	client.on('message', function(data){
		console.log( 'client says:' + data );
	});

	client.on('disconnect', function(){
		console.log('client disconnect');
	});
});


var
 sys = require('sys'),
 spawn = require('child_process').spawn,
 // filename = process.ARGV[2],
 filename = '/home/pomeh/minecraft/server.log',
tail;

if( !filename )
  return sys.puts('Usage: node server.js filename');

tail = spawn('tail', ['-f', '--line=10', filename]);
tail.stdout.on("data", function (data) {
	var _ = data.toString();
	console.log( 'tail says:' + _ );
	socket.broadcast( _ );
});


