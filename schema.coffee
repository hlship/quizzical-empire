# Defines the schema of data
# Exports three Mongoose Model objects: Question, Round, and Quiz

mongoose = require "mongoose"

Schema = mongoose.Schema

Question = new Schema
  title: String
  kind:
    type: String
    enum: [ "text" ]
  text: String
  answer: String
  value: Number
  { strict: true }

Round = new Schema
  kind:
    type: String
    enum: ["normal", "challenge", "wager"]
  questions: [Question]
  { strict: true }

Quiz = new Schema
  title: String
  created:
    type: Date
    default: -> new Date()
  location: String
  rounds: [Round]
  { strict: true }

module.exports =
  Question: mongoose.model('Question', Question)
  Round: mongoose.model('Round', Round)
  Quiz: mongoose.model('Quiz', Quiz)







