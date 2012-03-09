# Exports a single function that is passed the application object, to configure
# its routes

schema = require "../schema"
Flow = require "../lib/flow"
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

      flow = new Flow
      for i in [1..100]
        quiz = new Quiz
          title: "Test Quiz \# #{i}"
          location: "Undisclosed"

        quiz.save flow.add (err) ->
          throw err if err

      flow.join ->
        Quiz.find {}, (err, docs) ->
          throw err if err
          sendJSON res, docs
