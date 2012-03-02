# Exports a function that is passed the app, configures the app's routes

module.exports = (app) ->

  app.get "/",
    (req, res) ->
      res.render "index",
        title: "Quizzical Empire"

  require("./api")(app)
