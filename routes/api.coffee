schema = require "../schema"
Quiz = schema.Quiz

sendJSON = (res, json) ->
  res.contentType "text/json"
  # TODO: It would be cool to prettify this in development mode
  res.send JSON.stringify(json)

exports.quizzes = (req, res) ->
  Quiz.find {}, (err, docs) ->
    throw err if err
    sendJSON res, docs

