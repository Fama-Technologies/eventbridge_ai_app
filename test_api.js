const https = require('https');
const options = {
  hostname: 'api.eventbridge-ai.com',
  port: 443,
  path: '/api/vendor/packages/2',
  method: 'GET'
};
const req = https.request(options, res => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => console.log(data));
});
req.on('error', error => console.error(error));
req.end();
