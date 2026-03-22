const https = require('https');
const options = {
  hostname: '3nqhgc5y2l.execute-api.us-east-1.amazonaws.com',
  port: 443,
  path: '/dev/api/vendor/packages/2',
  method: 'GET'
};
const req = https.request(options, res => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => console.log(data));
});
req.on('error', error => console.error(error));
req.end();
