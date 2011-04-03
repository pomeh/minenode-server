// rewrite this function... very slow for now
var writeLine = (function() {
	var fs = require('fs');

	return function( fd, line ) {
		var data = '';

		try {
			data = fs.readFileSync( fd );
			if( data.length )
				data += '\n';
		} catch(e) {}

		fs.writeFileSync( fd, data + line );
	};
})();


var log = function( data ) {
	data = '[' + (new Date()).toString() + '] ' + data;

	console.log( data );
	writeLine( __dirname + '/test.log', data );
};



process.on('uncaughtException', function(err) {
	log( 'uncaughtException:' );
	try {
		log( err.toString() );
	} catch(e) {}
});


var
	http = require("http"),
	server
;

server = http.createServer(function( serverRequest, serverResponse ) {

	logRequest( serverRequest );


	var data = [];

	var url = serverRequest.url;

	if( /getversion.jsp/.test(url) )
	{
		// ne marche pas car il y a une vérification du login/session effectuée
		// à partir du serveur vers minecraft.net

		log( 'Local request handling for getVersion page' );
		serverResponse.writeHead( 200 );
		// this should return the username submitted !! don't care about the rest
		serverResponse.end( '1298470263000:bf31f35dc906bdfb160ce2a81b2ac360:pomehtest:1020920106385961697:' );
		// serverResponse.end( '1298470263000:4e1b50ac7600eb1c6039802a0114896b:pomeh:4729717232692250667:' );
		return;
	}
	else if( /joinserver.jsp/.test(url) )
	{
		log( 'Local request handling for joinserver page' );
		serverResponse.writeHead( 200 );
		serverResponse.end( 'OK' );
		return;
	}

	serverRequest.on( 'data', function(chunk) {
		log('serverRequest.data');
		log( chunk.toString() );
		data.push( chunk );
	});

	serverRequest.on( 'end', function() {
		log('serverRequest.end');

		sendRequest({
			host: '50.16.200.224', // www.minecraft.net
			port: 80,
			method: serverRequest.method,
			path: serverRequest.url,
			headers: serverRequest.headers,
			data: data,
			onBegin: function ( response ) {
				log( 'statusCode ' + response.statusCode );
				serverResponse.writeHead( response.statusCode, response.headers );
			},
			onData: function ( chunk ) {
				log( 'clientRequest.data' );
				log( chunk.toString() );
				serverResponse.write( chunk );
			},
			onEnd: function() {
				log('clientRequest.end');
				serverResponse.end();
			}
		});

	});

	setTimeout(function(){
		serverResponse.end();
	}, 2000);



});
server.listen(9192);
log( 'Server is running on port 8080' );


function logRequest( req ) {
    log( '\n\n\nRequete entrante' );

    var text = '';

    text += ' ' + req.socket.remoteAddress;
    text += ' ' + req.method;
    text += ' ' + req.url;

    log( text );
}




function sendRequest( params ) {

	var
	options = {
		host: params.host,
		port: params.port || 80,
		method: params.method || 'GET',
		path: params.path || '/',
		headers: params.headers || {},
	},
	settings = {
		begin: params.onBegin || function() {},
		data: params.onData || function() {},
		end: params.onEnd || function() {},
	}
	data = params.data || [],
	l = data.length, queryString = data.join('&')
	;

	if( queryString.length )
	{
		options.path += '?' + queryString;
	}


	var clientRequest = http.request(options, function( clientResponse ) {
		//	clientResponse.setEncoding('utf8');

		settings.begin( clientResponse );

		clientResponse.on( 'data', settings.data );
		clientResponse.on( 'end', settings.end );
	});

	for( var i=0; i < l; i++ )
	{
		clientRequest.write( data[i] );
	}

	clientRequest.end();
}

