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

QuestionCollection = Collection.extend
  model: Question

Round = Model.extend
  defaults: ->
    questions: new QuestionCollection

  parse: (response) ->
    models = _(response.questions).map (raw) ->
      new Question raw, { parse: true }

    response.questions = new QuestionCollection models

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
    models = _(response.rounds).map (raw) ->
      new Round raw, { parse: true }

    response.rounds = new RoundCollection models

    return response

  defaults: ->
    rounds: new RoundCollection

  enableSave: ->
    (not isBlank @get "title") and
    _(@get "rounds").all (round) -> round.enableSave()

QuizList = Collection.extend
  model: Quiz
  url: "/api/quizzes"

# Destructuring local names into an object FTW!
window.Quizzical = {isBlank, Question, Quiz, QuizList,
  Round, RoundCollection }