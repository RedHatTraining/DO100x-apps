const express = require('express');
const process = require('process');
const { generateEmail } = require('./generate-email');

const app = express();

app.get('/random-email', async (req, res) => {
  const generatedEmail = await generateEmail();

  res.send(JSON.stringify(generatedEmail));
});

const PORT = process.env.PORT || 8081;
app.listen(PORT, function () {
  console.log(`Listening on port ${PORT}!`)
});