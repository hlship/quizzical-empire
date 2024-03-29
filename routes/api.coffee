# Exports a single function that is passed the application object, to configure
# its routes

schema = require "../schema"
Flow = require "../lib/flow"
_ = require "underscore"
Quiz = schema.Quiz

sendError = (res, message) ->
  res.send(message || "An unexpected server-side error has occurred.",
    500)

handleError = (res, fn) ->
  (err, arg) ->
    if err
      console.error "Request processing failure: %j", err
      sendError res, err.err
    else
      fn(arg)

extractError = (err) ->
  _(_.values(err?.errors)).chain()
    .pluck("message").first()
    .value() or err?.message

saveAndReturnQuiz = (res, quiz) ->
  quiz.save (err) ->
    if err?
      switch err?.code
        when 11000
          sendError res, "Quiz title must be unique"
        else
          console.error "Unexpected error on save(): %j", err
          sendError res, extractError err

      return

    res.send quiz

getAndReturnQuiz = (req, res) ->
  quiz = Quiz.findById req.params.id,
    handleError res, (doc) -> res.send doc

module.exports = (app) ->

  # Create a new Quiz
  app.post "/api/quiz",
    (req, res) ->
      quiz = new Quiz req.body
      saveAndReturnQuiz res, quiz

  # Update an existing Quiz
  app.put "/api/quiz/:id",
    (req, res) ->
      Quiz.findById req.params.id,
        handleError res, (quiz) ->
          _.extend quiz, req.body
          saveAndReturnQuiz res, quiz

  # A Backbone odditty: a Model that comes from a Collection is always
  # saved back based on the same URL from which the collection as a
  # whole was obtained.
  app.get "/api/quiz/:id", getAndReturnQuiz
  app.get "/api/quizzes/:id", getAndReturnQuiz

  # Returns all documents, ordered by creation date (most recent first)
  app.get "/api/quizzes",
    (req, res) ->
      Quiz
      .find()
      .desc("created")
      .fields("title location created")
      .run handleError res, (docs) -> res.send docs

  app.delete "/api/quizzes/:id",
    (req, res) ->
      # very dangerous! Need to add some permissions checking
      Quiz.remove { _id: req.params.id },
        handleError res, () -> res.send result: "ok"

  app.get "/api/create-test-data",
    (req, res) ->

      failed = false

      now = Date.now().toString(16)

      flow = new Flow
      for i in [1..100]
        quiz = new Quiz
          title: "Test Quiz \# #{i} -- #{now}"
          location: "Undisclosed"

        quiz.save flow.add (err) ->
          if err and not failed
            sendError res, err
            failed = true

      flow.join ->
        if not failed
          res.send result: "ok"

