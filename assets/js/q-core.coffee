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

Quiz = Model.extend
  idAttribute: "_id"
  default: ->
    rounds: [] # of Round
  enableSave: ->
    (not isBlank @get "title") and
    _(@get "rounds").all (round) -> round.enableSave()

# What does Backbone do with nested entities without
# their own id?
Round = Model.extend
  default: ->
    questions: [] # of Question
  enableSave: ->
    return false if isBlank @get "title"

    questions = @get "questions"

    _.all questions, (q) -> q.enableSave()

RoundCollection = Collection.extend
  model: Round

Question = Model.extend
  enableSave: -> true

QuizList = Collection.extend
  model: Quiz
  url: "/api/quizzes"

# Destructuring local names into an object FTW!
window.Quizzical = {isBlank, Question, Quiz, QuizList,
  Round, RoundCollection }