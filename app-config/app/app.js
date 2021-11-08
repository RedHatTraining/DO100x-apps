const express = require('express');
const fs = require('fs');
const app = express();

// read in the APP_MSG env var
const response = `Value in the APP_MSG env var is => ${process.env.APP_MSG}\n`;

app.get('/', function (req, res) {

    // Read in the secret file
    fs.readFile('/opt/app-root/secure/myapp.sec', 'utf8', function (secerr,secdata) {
        if (secerr) {
            console.log(secerr + '\n');
          res.send(response + secerr + '\n');
        }
        else {
            res.send(`${response}The secret is => ${secdata}\n`;
        }
    });

});

app.listen(8080, function () {
  console.log('Server listening on port 8080...');
});
