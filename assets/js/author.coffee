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

QuizList = Collection.extend
  model: Quiz
  url: "/api/quizzes"

ConfirmDeleteDialog = View.extend

  initialize: ->
    @render()

  render: ->
    @$el.html fromMustacheTemplate "delete-quiz-modal",
      title: @model.escape "title"

    $("body").append(@$el)

    @$el.addClass "fade in"

    # After the modal dialog is hidden, remove it from the DOM
    @$el.modal().on "hidden", =>
      @remove()

   dismissDialog: ->
    @$el.modal "hide"

   doConfirm: ->
     @trigger "confirm", @model

   events:
    "click .x-confirm": "doConfirm"
    "click .btn": "dismissDialog"

QuizTableRowView = View.extend
  tagName: "tr"

  initialize: ->
    @model.on "change", @render, this
    @model.on "destroy", @remove, this

    @template = readTemplate "quiz-table-row-template"

  events:
    "click .x-delete": "deleteDialog"
    "click .x-edit": "editQuiz"

  render: ->

    @$el.html Mustache.render @template,
      title: @model.escape "title" || "<em>No Title</em>"
      location: @model.escape "location"
      created: @model.get "created"

    this

  deleteDialog: ->

    new ConfirmDeleteDialog(model: @model).on "confirm", => @model.destroy()

  editQuiz: ->

    new QuizEditorView
      model: @model
      collection: @collection

# Owns the table that displays the current list of Quizzes, including
# the buttons used to create a new quiz, etc.
QuizTableView = View.extend

  initialize: ->

    @quizzes = new QuizList

    @$el.html $("#quiz-table-template").html()

    # Hide the alert and the table initially, while the content is
    # being fetched via Ajax
    @$(".alert, table").hide()

    @quizzes.on "reset", @addAll, this
    @quizzes.on "add", @addOne, this
    @quizzes.on "destroy", @render, this

    @quizzes.fetch()

    @$(".x-create-test-data").popover
      title: "For Testing"
      content: """Creates many Quizzes with random text, for testing purposes.
                This will be removed in the final application."""

  addOne: (quiz, collection, options) ->
    view = new QuizTableRowView
      model:quiz
      collection: @quizzes

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
    new QuizEditorView
      model: new Quiz,
      collection: @quizzes

  events:
    "click .x-create-test-data": "createTestData"
    "click .x-create-new": "createNewQuiz"

# QuizEditorView creates and manages a top level tab for a Quiz.
# Creates a clone of the model which is editted. The original model is
# updated at the end.  TODO: Split this up into one View for handling
# the tabs and the save/cancel button, and additional views for
# everything else.
QuizEditorView = View.extend

  className: "tab-pane"

  # Create the top level tab and select it
  initialize: ->

    @originalModel = @model
    @model = @model.clone()
    @valid = not @model.isNew()

    tabId = _.uniqueId "quiztab_"

    $("#top-level-tabs > ul").append(
      "<li><a href='##{tabId}' data-toggle='tab'>#{@quizName()}</a></li>")

    # Set the id attribute, read the template containing the form,
    # and move it into place.
    @$el.attr("id", tabId).html(
      readTemplate "quiz-edit-form").appendTo("#top-level-tabs > .tab-content")

    @$(".x-cancel").tooltip()

    @updateSaveButton()

    @viewTab = $("#top-level-tabs .nav-tabs a:[href='##{tabId}']")

    @viewTab.tab "show"

    $("#top-level-tabs .nav-tabs a:last").tab "show"

    @populateFields()

    @model.on "change:title", @updateTabTitle, this
    @on "checkvalid", @checkValid, this

    # Move the cursor into the title field
    @$(".x-title input").select()

    # Create a nested view that's responsible for editting, adding,
    # and deleting Rounds
    new QuizRoundsEditorView
      model: @model
      el: @$(".x-rounds").first()

  remove: ->
    displayFirstTab()

    @$(".x-cancel").tooltip "hide"

    # And the LI containing the tab's A
    @viewTab.parent().remove()

    @$el.remove()

    # Don't have to worry about model events, since
    # because we cloned the original model

  updateTabTitle: ->
    @viewTab.html @quizName()

  refreshValid: ->
    @valid = @$(".control-group.error").length == 0
    @updateSaveButton()

  # Disables the save button unless @valid
  updateSaveButton: ->
    @$(".x-save").attr "disabled", not @valid

  populateFields: ->
    @$(".x-title input").val(@model.get("title"))
    @$(".x-location input").val(@model.get("location"))

  quizName: ->
    @model.escape("title") || "<em>New Quiz</em>"

  # Looks like a bit of boilerplate to keep the model
  # and the view synchronized here.
  storeTitle: ->
    title = event.target.value

    @model.set "title", title

    if isBlank title
      @$(".x-title .help-inline").html "Title may not be blank"
      @$(".x-title").addClass "error"
    else
      @$(".x-title").removeClass "error"

    @refreshValid()

  storeLocation: (event) ->
    @model.set "location", event.target.value

  doCancel: ->
    # TODO: A modal warning

    @remove()

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
        @remove()
        insert = @originalModel.isNew()

        # Copy stuff over to the original mode
        @originalModel.set @model

        # Add to top of collection if was new (otherwise
        # it must already be in place inside the collection).
        if insert
          @collection.add new Quiz(@originalModel), at: 0

  events:
    "change .x-title input": "storeTitle"
    "change .x-location input": "storeLocation"
    "click .x-cancel" : "doCancel"
    "click .x-save" : "doSave"

# Manages the QuizRoundEditorViews for the rounds collection of the
# Quiz model. Also includes a control to add new Quiz rounds.
QuizRoundsEditorView = View.extend
  initialize: ->
    @$el.html readTemplate "rounds-editor"


# Now some page-load-time initialization:

jQuery ->

  displayFirstTab()

  new QuizTableView
    el: $("#quiz-table-view")
