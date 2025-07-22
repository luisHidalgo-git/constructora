const mongoose = require('mongoose');

const statsSchema = new mongoose.Schema({
  activeProjects: {
    type: Number,
    default: 0
  },
  activeAlerts: {
    type: Number,
    default: 0
  },
  totalBudget: {
    type: String,
    default: '$0'
  },
  averageProgress: {
    type: Number,
    min: 0,
    max: 1,
    default: 0
  },
  lastUpdated: {
    type: Date,
    default: Date.now
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Stats', statsSchema);