import express, { Router } from "express";

const app = express();
const route = Router();

const port = process.env.PORT || process.env.OPENSHIFT_NODEJS_PORT || 8080;
const ip = process.env.IP || process.env.OPENSHIFT_NODEJS_IP || "0.0.0.0";

const version = "2.0";
const started = Math.floor(Date.now() / 1000);

app.use("/", route);

// A route that says hello
route.get("/", (_req, res) => {
  res.send(`Hello! This is the index page for the app, version: ${version}\n`);
});

route.get("/ready", (_req, res) => {
  const now = Math.floor(Date.now() / 1000);
  const lapsed = now - started;
  if (lapsed > 30) {
    res.send("Ready for service requests...\n");
  } else {
    res.status(503);
    res.send("Error! Service not ready for requests...\n");
  }
});

app.listen(port, ip, () => {
  console.log(
    `do100-multi-version server running version ${version} on http://${ip}:${port}`
  );
});
