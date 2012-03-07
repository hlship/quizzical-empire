# Exports a single function that is passed the application object, to configure
# its routes

schema = require "../schema"
Quiz = schema.Quiz

sendJSON = (res, json) ->
  res.contentType "text/json"
  # TODO: It would be cool to prettify this in development mode
  res.send JSON.stringify(json)

module.exports = (app) ->

  app.get "/api/quizzes",
    (req, res) ->
      Quiz.find {}, (err, docs) ->
        throw err if err
        sendJSON res, docs

  app.delete "/api/quizzes/:id",
    (req, res) ->
      console.log "Deleting quiz #{req.params.id}"
      # very dangerous! Need to add some permissions checking
      Quiz.remove { _id: req.params.id }, (err) ->
        throw err if err
        sendJSON res, { result: "ok" }

  app.get "/api/create-test-data",
    (req, res) ->
      remaining = 100

      keepCount = (err) ->
        throw err if err
        remaining--

        if (remaining == 0)
          Quiz.find {}, (err, docs) ->
            throw err if err
            sendJSON res, docs

      for i in [1..remaining]
        new Quiz(title: "Test Quiz \# #{i}").save keepCount