# Exports a single function that is passed the application object, to configure
# its routes

schema = require "../schema"
Flow = require "../lib/flow"
Quiz = schema.Quiz

module.exports = (app) ->

  # Create a new Quiz
  app.post "/api/quiz",
    (req, res) ->
      quiz = new Quiz req.body
      quiz.save (err, doc) ->
        if err
          console.error "POST /api/quiz error: %j", err
          switch err.code
            when 11000
              console.error "unique fail"
              res.send
                result: "fail"
                hint: "title"
                message: "Quiz title must be unique."
            else
              res.send(
                err.err || "An unexpected server-side error has occurred.",
                500)
          return

        console.log "Sending /api/quiz response: %j", doc

        res.send
          result: "ok"
          quiz: doc

  # Returns all documents, ordered by creation date (most recent first)
  app.get "/api/quizzes",
    (req, res) ->
      Quiz
      .find()
      .desc("created")
      .fields("title location created")
      .run (err, docs) ->
         throw err if err
         res.send docs

  app.delete "/api/quizzes/:id",
    (req, res) ->
      console.log "Deleting quiz #{req.params.id}"
      # very dangerous! Need to add some permissions checking
      Quiz.remove { _id: req.params.id }, (err) ->
        throw err if err
        res.send result: "ok"

  app.get "/api/create-test-data",
    (req, res) ->

      now = Date.now().toString(16)

      flow = new Flow
      for i in [1..100]
        quiz = new Quiz
          title: "Test Quiz \# #{i} -- #{now}"
          location: "Undisclosed"

        quiz.save flow.add (err) ->
          throw err if err

      flow.join ->
        res.send result: "ok"

