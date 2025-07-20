const mongoose = require('mongoose');

const updateNoteSchema = new mongoose.Schema({
  content: {
    type: String,
    required: [true, 'El contenido de la nota es requerido'],
    trim: true,
    maxlength: [2000, 'La nota no puede exceder 2000 caracteres']
  },
  project: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Project',
    required: true
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  updateType: {
    type: String,
    enum: ['progress', 'status', 'indicators', 'general'],
    default: 'general'
  },
  previousValues: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  newValues: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('UpdateNote', updateNoteSchema);