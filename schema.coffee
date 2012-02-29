# Defines the schema of data

mongoose = require "mongoose"

Schema = mongoose.Schema
ObjectId = Schema.ObjectId

Question = new Schema
  title: String
  text: String
  answer: text

Round = new Schema
  kind:
    type: String
    enum: ["normal", "challenge", "wager"]
  questions: [Question]

Quiz = new Schema
  title: String
  location: String
  rounds: [Round]

mongoose.model('Question', Question)
mongoose.model('Round', Round)
mongoose.model('Quiz', Quiz)



