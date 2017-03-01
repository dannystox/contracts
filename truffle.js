module.exports = {
  build: {
    "index.html": "index.html",
    "app.js": [
      "javascripts/app.js"
    ],
    "app.css": [
      "stylesheets/app.css"
    ],
    "images/": "images/"
  },
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*"
    }
  },
  rpc: {
    host: "localhost",
    port: 8545,
    from: "0xcdc57ea1654b2c0f422299d26dca3310552198fe"
  }
};
