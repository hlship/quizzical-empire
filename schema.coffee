# Defines the schema of data
# Exports three Mongoose Model objects: Question, Round, and Quiz

mongoose = require "mongoose"

Schema = mongoose.Schema

Question = new Schema
  title:
    type: String
    required: true
  kind:
    type: String
    enum: [ "text" ]
  text:
    type: String
    required: true
  answer:
    type: String
    required: true
  value: Number
  { strict: true }

Round = new Schema
  kind:
    type: String
    required: true
    enum: ["normal", "challenge", "wager"]
  title:
    type: String
    required: true
  questions: [Question]
  { strict: true }

Quiz = new Schema
  title:
    type: String
    required: true
    unique: true
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
