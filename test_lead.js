const axios = require('axios');
axios.post('https://3nqhgc5y2l.execute-api.us-east-1.amazonaws.com/dev/api/vendor/leads', {
  vendorId: "1",
  customerId: "10",
  title: "Test Inquiry",
  eventDate: "2026-05-01",
  eventTime: "12:00",
  location: "Test",
  budget: 500,
  guests: 100,
  clientMessage: "Test Msg"
}).then(res => console.log(res.data)).catch(err => console.error(err.response?.data || err.message));
