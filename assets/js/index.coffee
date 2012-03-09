[Model, Collection, View] = [Backbone.Model, Backbone.Collection, Backbone.View]

Quiz = Model.extend
  idAttribute: "_id"

QuizList = Collection.extend
  model: Quiz
  url: "/api/quizzes"

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
      location: @model.get("location")
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

# Owns the table that displays the current list of Quizzes, including
# the buttons used to create a new quiz, etc.
QuizTableView = View.extend

  initialize: ->

    @quizzes = new QuizList

    @$el.html $("#quiz-table-template").html()

    @quizzes.bind "reset", @addAll, this
    @quizzes.bind "add", @addOne, this
    @quizzes.bind "destroy", @render, this

    @quizzes.fetch()

    @$(".x-create-test-data").popover
      title: "For Testing"
      content: """Creates many Quizzes with random text, for testing purposes.
                This will be removed in the final application."""

  addOne: (quiz) ->
    view = new QuizTableRowView model:quiz

    @$("tbody").append view.render().el

  addAll: (quizzes) ->
    @$("tbody").empty()

    quizzes.each (quiz) => @addOne quiz
    @render()

  render: ->
    if @quizzes.length == 0
      @$(".alert").show()
      @$("table").hide()
    else
      @$(".alert").hide()
      @$("table").show()
    this

  createTestData: ->
    b = @$(".x-create-test-data")
    b.button('loading').popover('hide')

    $.ajax "/api/create-test-data",
      context: this
      success: (data, status) ->
        b.button('reset')
        @quizzes.reset data


  events:
    "click .x-create-test-data": "createTestData"

# Now some page-load-time initialization:

jQuery ($) ->

  # This could be moved to a "layout.coffee" perhaps:
  $(".invisible").hide().removeClass("invisible")

  # Find the main tab view and select the first tab
  $("#top-level-tabs a:first").tab "show"

  # We get an unwanted flash unless these are hidden before being copied
  # out to the DOM by the QuizTableView
  $("#quiz-table-template").find(".alert, table").hide()

  new QuizTableView
    el: $("#quiz-table-view")
