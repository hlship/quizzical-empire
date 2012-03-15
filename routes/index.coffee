# Exports a function that is passed the app, configures the app's routes

module.exports = (app) ->

  # May move this to a different url in the future.
  app.get "/",
    (req, res) ->
      res.render "author",
        title: "Quizzical Empire"

  require("./api")(app)
