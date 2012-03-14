[Model, Collection, View] = [Backbone.Model, Backbone.Collection, Backbone.View]

displayFirstTab = ->
  $("#top-level-tabs a:first").tab "show"

readTemplate = (scriptId) ->
  jQuery("##{scriptId}").get(0).innerHTML

fromMustacheTemplate = (scriptId, attributes) ->
  Mustache.render readTemplate(scriptId), attributes

isBlank = (str) ->
  _.isNull(str) or
  _.isUndefined(str) or
  str.trim() == ""

Quiz = Model.extend
  idAttribute: "_id"
  urlRoot: "/api/quiz"
  validate: (attrs) ->
    return "Quiz title may not be blank" if isBlank attrs.title

    return null

QuizList = Collection.extend
  model: Quiz
  url: "/api/quizzes"

QuizTableRowView = View.extend
  tagName: "tr"

  initialize: ->
    @model.on "change", @render, this
    @model.on "destroy", @remove, this

    @template = readTemplate "quiz-table-row-template"

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

    @quizzes.on "reset", @addAll, this
    @quizzes.on "add", @addOne, this
    @quizzes.on "destroy", @render, this

    @quizzes.fetch()

    @$(".x-create-test-data").popover
      title: "For Testing"
      content: """Creates many Quizzes with random text, for testing purposes.
                This will be removed in the final application."""

  addOne: (quiz, collection, options) ->
    view = new QuizTableRowView model:quiz

    # Special case for inserting at index 0, which happens when a new quiz
    # is added in the UI.
    fname = if options? and options.index is 0 then "prepend" else "append"

    @$("tbody")[fname] view.render().el

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
        @quizzes.fetch()


  createNewQuiz: ->
    new QuizEditorView(
      model: new Quiz,
      collection: @quizzes).render()

  events:
    "click .x-create-test-data": "createTestData"
    "click .x-create-new": "createNewQuiz"

# QuizEditorView creates and manages a top level tab for the Quiz.
QuizEditorView = View.extend

  className: "tab-pane"

  # Create the top level tab and select it
  render: ->
    tabId = _.uniqueId "quiztab_"

    $("#top-level-tabs > ul").append(
      "<li><a href='##{tabId}' data-toggle='tab'>#{@quizName()}</a></li>")

    # Set the id attribute, read the template containing the form,
    # and move it into place.
    @$el.attr("id", tabId).html(
      readTemplate "quiz-edit-form").appendTo("#top-level-tabs > .tab-content")

    @updateSaveButton()

    @viewTab = $("#top-level-tabs .nav-tabs a:[href='##{tabId}']")

    @viewTab.tab "show"

    $("#top-level-tabs .nav-tabs a:last").tab "show"

    @populateFields()

    @model.on "change:title", @updateTabTitle, this
    @model.on "change", @updateSaveButton, this

    # Move the cursor into the title field
    @$(".x-title").select()

  updateTabTitle: ->
    @viewTab.html @quizName()

  # Disables the save button unless the model is valid
  updateSaveButton: ->
    @$(".x-save").attr "disabled", not @model.isValid()

  populateFields: ->
    @$(".x-title").val(@model.get("title"))
    @$(".x-location").val(@model.get("location"))

  removeView: ->
    # TODO: Leaves event listeners on the model, but the model should only
    # be accessible to this instance anyway.

    # Display the main tab
    displayFirstTab()

    # Remove the tab-pane div
    @$el.remove()
    # And the LI containing the tab's A
    @viewTab.parent().remove()

  quizName: ->
    @model.escape("title") || "<em>New Quiz</em>"

  # Looks like a bit of boilerplate to keep the model
  # and the view synchronized here.
  storeTitle: ->
    @model.set "title", @$(".x-title").val()

  storeLocation: ->
    @model.set "location", @$(".x-location").val()

  doCancel: ->
    # TODO: A modal warning
    @removeView()

  errorAlert: (message) ->
    alert = fromMustacheTemplate "standard-error-alert",
      content: message

    @$(".x-alert-container").append alert

  doSave: ->
    b = @$(".x-save").button("loading")

    @model.save null,
      error: (model, response) =>
        b.button("reset")
        @errorAlert response.responseText or response.statusText

      success: (model, response) =>
        b.button("reset")
        switch response.result
          when "ok"
            @removeView()
            @collection.add new Quiz(response.quiz), at: 0
          when "fail"
            @errorAlert response.message
            # The "error" class name goes on the div.control-group around the
            # text field.
            @$(".x-#{response.hint}")
              .select()
              .parents(".control-group")
              .addClass("error")
          else
            @errorAlert "Unexpected response from server."


  events:
    "change .x-title": "storeTitle"
    "change .x-location": "storeLocation"
    "click .x-cancel" : "doCancel"
    "click .x-save" : "doSave"

# Now some page-load-time initialization:

jQuery ->

  # This could be moved to a "layout.coffee" perhaps:
  $(".invisible").hide().removeClass("invisible")

  displayFirstTab()

  # We get an unwanted flash unless these are hidden before being copied
  # out to the DOM by the QuizTableView
  $("#quiz-table-template").find(".alert, table").hide()

  new QuizTableView
    el: $("#quiz-table-view")
