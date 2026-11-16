// Synthetic local mail transport: captures in memory, never relays or resolves
// recipient domains. Ports are private to the disposable Compose network.
const { SMTPServer } = require('smtp-server');
const { readFileSync } = require('node:fs');
const http = require('node:http');
const messages = [];
const server = new SMTPServer({
  key: readFileSync('/tls/privkey.pem'), cert: readFileSync('/tls/fullchain.pem'),
  authOptional: false, allowInsecureAuth: false, logger: false,
  size: 64 * 1024, disabledCommands: ['VRFY', 'EXPN'],
  onAuth(auth, session, done) {
    if (auth.username !== 'synthetic' || auth.password !== process.env.CAPTURE_PASSWORD) return done(new Error('Authentication failed'));
    done(null, { user: 'synthetic' });
  },
  onRcptTo(address, session, done) {
    if (!address.address.endsWith('@demo.test')) return done(new Error('Synthetic @demo.test recipients only'));
    done();
  },
  onData(stream, session, done) {
    const chunks = [];
    stream.on('data', chunk => chunks.push(chunk));
    stream.on('end', () => {
      if (stream.sizeExceeded) return done(new Error('Message too large'));
      if (messages.length >= 100) return done(new Error('Synthetic mailbox full'));
      const text = Buffer.concat(chunks).toString('utf8');
      messages.push({ to: session.envelope.rcptTo.map(x => x.address),
        reference: text.match(/inquiry-([a-f0-9]{24})@eoapp\.local/i)?.[1],
        // No body/PII is exposed by the private inspection endpoint.
        tls: session.secure, authenticated: Boolean(session.user) });
      done();
    });
    stream.on('error', done);
  },
});
server.on('error', () => { console.error('Synthetic SMTP capture failed'); process.exitCode = 1; });
server.listen(2525, '0.0.0.0');
http.createServer((request, response) => {
  response.setHeader('Content-Type', 'application/json');
  response.setHeader('Cache-Control', 'no-store');
  if (request.url === '/health') return response.end(JSON.stringify({ status: 'ready', synthetic: true }));
  if (request.url === '/messages') return response.end(JSON.stringify({ messages }));
  response.writeHead(404).end('{}');
}).listen(8081, '0.0.0.0');
