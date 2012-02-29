express = require "express"
routes = require "./routes"
mongoose = require "mongoose"

app = module.exports = express.createServer()

app.configure ->
  app.set "views", "#{__dirname}/views"
  app.set "view engine", "jade"
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static "#{__dirname}/public"
  express.errorHandler.title = "Quizzical Empire Online"

app.configure "development", ->
  app.use express.errorHandler  dumpExceptions: true, showStack:true

app.configure "production", ->
  app.use express.errorHandler()

app.get "/", routes.index

app.listen process.env.PORT || 3000

dburl = process.env.MONGOLAB_URI || "mongodb://localhost/quizzical-empire"

console.log "Connecting to #{dburl} ..."

mongoose.connect dburl

console.log "Quizzical Empire: Express server listening on port %d in %s mode", app.address().port, app.settings.env
