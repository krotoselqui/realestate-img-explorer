const { createServer } = require('http');
const { parse } = require('url');
const next = require('next');

const dev = process.env.NODE_ENV !== 'production';
const port = parseInt(process.env.PORT, 10) || 3001;

// IPv4とIPv6の両方でリッスンするための設定
const app = next({
  dev,
  hostname: '::',
  port
});
const handle = app.getRequestHandler();

// グローバルなエラーハンドリング
process.on('uncaughtException', (err) => {
  console.error('[Uncaught Exception]', err);
});

process.on('unhandledRejection', (err) => {
  console.error('[Unhandled Rejection]', err);
});

app.prepare().then(() => {
  createServer(async (req, res) => {
    try {
      const parsedUrl = parse(req.url, true);
      
      // アクセスログを記録
      console.log(`[${new Date().toISOString()}] ${req.method} ${req.url} - ${req.headers['user-agent']}`);

      await handle(req, res, parsedUrl);
    } catch (err) {
      console.error('Error occurred handling', req.url, err);
      res.statusCode = 500;
      res.end('Internal Server Error');
    }
  })
    .once('error', (err) => {
      console.error(err);
      process.exit(1);
    })
    .listen(port, '::', () => {
      console.log(`> Ready on http://[::]:${port}`);
    });
});