const express = require('express');
const process = require('process');
const { generateEmail } = require('./generate-email');

const app = express();

app.get('/random-email', async (req, res) => {
  const generatedEmail = await generateEmail();

  res.send(JSON.stringify(generatedEmail));
});

const PORT = process.env.PORT;
app.listen(PORT, function () {
  console.log(`Listening on port ${PORT}!`)
});