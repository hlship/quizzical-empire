# Defines request handling functions; see app.coffee for the routing to these functions.

schema = require "../schema"
Quiz = schema.Quiz

exports.index = (req, res) ->

  Quiz.find {}, (err, docs) ->
    res.render "index",
      title: "Quizzical Empire"
      quizzes: docs


