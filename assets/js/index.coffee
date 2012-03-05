[Model, Collection, View] = [Backbone.Model, Backbone.Collection, Backbone.View]

Quiz = Model.extend
  idAttribute: "_id"

QuizList = Collection.extend
  model: Quiz
  url: "/api/quizzes"

Quizzes = new QuizList()

QuizTableRowView = View.extend
  tagName: "tr"

  initialize: ->
    @model.bind "change", @render, this
    @model.bind "destroy", @remove, this

    @template = $("#quiz-table-row-template").get(0).innerHTML

  events:
    "click .x-delete": "deleteDialog"

  render: ->

    @$el.html Mustache.render @template,
      title: @model.get("title")
      created: @model.get("created")

    this

  deleteDialog: ->
    dialog = $("#delete-quiz-modal")
    dialog.find(".x-title").html @model.escape("title")

    dialog.find(".btn-danger")
      .unbind("click")
      .one "click", =>
        @model.destroy()

    dialog.modal()


QuizTableView = View.extend

  initialize: ->

    @$el.html $("#quiz-table-template").html()

    @count = 0
    Quizzes.bind "reset", @addAll, this
    Quizzes.bind "add", @addOne, this

    Quizzes.fetch()

  addOne: (quiz) ->
    @count++

    view = new QuizTableRowView model:quiz

    @$("tbody").append view.render().el

  addAll: (quizzes) ->
    @count = 0
    @$("tbody").empty()

    quizzes.each (quiz) => @addOne quiz
    @render()

  render: ->
    if @count == 0
      @$(".alert").show()
      @$("table").hide()
    else
      @$(".alert").hide()
      @$("table").show()
    this

jQuery ($) ->

  # We get an unwanted flash unless these are hidden before being copied
  # out to the DOM by the QuizTableView
  $("#quiz-table-template").find(".alert, table").hide()

  new QuizTableView
    el: $("#quiz-table-view")
