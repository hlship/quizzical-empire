exports.index = (req, res) ->
  res.render "index", { title: "Quizzical Empire" }

exports.divide = (req, res) ->
  res.render "divide",
    title: "Divide #{req.params.numerator} by #{req.params.denominator}"
    result: req.params.numerator / req.params.denominator


