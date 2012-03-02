express = require "express"
routes = require "./routes"
mongoose = require "mongoose"

app = module.exports = express.createServer()

app.configure ->
  app.set "views", "#{__dirname}/views"
  app.set "view engine", "jade"
  app.set "view options", layout:false
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use require("connect-assets")()
  app.use express.static "#{__dirname}/public"
  express.errorHandler.title = "Quizzical Empire Online"

app.configure "development", ->
  app.use express.errorHandler  dumpExceptions: true, showStack:true

app.configure "production", ->
  app.use express.errorHandler()

app.get "/", routes.index

app.get "/api/quizzes", routes.api.quizzes

app.listen process.env.PORT || 3000

dburl = process.env.MONGOLAB_URI || "mongodb://localhost/quizzical-empire"

console.log "Connecting to #{dburl} ..."

mongoose.connect dburl, (err) ->
  if err
    console.log "Connection errors: #{err}"
    throw err

  Quiz = require("./schema").Quiz

  Quiz.count {}, (err, n) ->
    throw err if err
    console.log "Found #{n} quizzes"
    if n is 0
      console.log "Inserting a couple of Quizzes"
      new Quiz(title: "A Mind Forever Voyaging").save()
      new Quiz(title: "Foundation And Empire").save()

console.log "Quizzical Empire: Express server listening on port %d in %s mode",
  app.address().port, app.settings.env
