# Defines request handling functions; see app.coffee for the routing to these functions.

exports.index = (req, res) ->
    res.render "index",
      title: "Quizzical Empire"

exports.api = require "./api"
