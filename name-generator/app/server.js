const express = require('express');
const { generateName } = require('./generate-name');

const app = express();

app.get('/random-name', (req, res) => {
  const generatedName = generateName();

  res.send(JSON.stringify(generatedName));
});

const PORT = process.env.PORT;
app.listen(PORT, function () {
  console.log(`Listening on port ${PORT}!`)
});