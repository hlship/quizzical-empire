# Defines the core aspects of the Quizzical namespace
# Expects a number of modules to already be loaded:
#   jQuery
#   Underscore
#   Backbone

[Model, Collection] = [Backbone.Model, Backbone.Collection]

# Some utility functions

isBlank = (str) ->
  _.isNull(str) or
  _.isUndefined(str) or
  str.trim() is ""

# Models and Collections
# Backbone expressly doesn't deal with relationships, that's left as
# an exercise. We implement the parse method on each Model
# to convert raw JSON to Model objects.

Question = Model.extend
  enableSave: -> true

Round = Model.extend
  default: ->
    questions: [] # of Question

  parse: (response) ->
    response.questions = _(response.questions).map (raw) ->
      new Question raw, { parse: true }
    return response

  enableSave: ->
    return false if isBlank @get "title"

    questions = @get "questions"

    _.all questions, (q) -> q.enableSave()

RoundCollection = Collection.extend
  model: Round

Quiz = Model.extend
  idAttribute: "_id"

  urlRoot: "/api/quiz"

  parse: (response) ->
    response.rounds = _(response.rounds).map (raw) ->
      new Round raw, { parse: true }
    return response

  default: ->
    rounds: [] # of Round

  enableSave: ->
    (not isBlank @get "title") and
    _(@get "rounds").all (round) -> round.enableSave()

QuizList = Collection.extend
  model: Quiz
  url: "/api/quizzes"

# Destructuring local names into an object FTW!
window.Quizzical = {isBlank, Question, Quiz, QuizList,
  Round, RoundCollection }