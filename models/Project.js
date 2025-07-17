const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'El nombre del proyecto es requerido'],
    trim: true,
    maxlength: [200, 'El nombre no puede exceder 200 caracteres']
  },
  clientName: {
    type: String,
    required: [true, 'El nombre del cliente es requerido'],
    trim: true,
    maxlength: [200, 'El nombre del cliente no puede exceder 200 caracteres']
  },
  description: {
    type: String,
    required: [true, 'La descripción es requerida'],
    trim: true,
    maxlength: [1000, 'La descripción no puede exceder 1000 caracteres']
  },
  location: {
    type: String,
    required: [true, 'La ubicación es requerida'],
    trim: true,
    maxlength: [200, 'La ubicación no puede exceder 200 caracteres']
  },
  budget: {
    type: String,
    required: [true, 'El presupuesto es requerido'],
    trim: true
  },
  startDate: {
    type: String,
    required: [true, 'La fecha de inicio es requerida']
  },
  endDate: {
    type: String,
    required: [true, 'La fecha de fin es requerida']
  },
  progress: {
    type: Number,
    min: [0, 'El progreso no puede ser menor a 0'],
    max: [1, 'El progreso no puede ser mayor a 1'],
    default: 0
  },
  status: {
    type: String,
    enum: ['Activo', 'Pausado', 'Completado', 'Cancelado'],
    default: 'Activo'
  },
  keyIndicators: {
    Calidad: {
      type: Number,
      min: 0,
      max: 1,
      default: 0
    },
    Tiempo: {
      type: Number,
      min: 0,
      max: 1,
      default: 0
    },
    Presupuesto: {
      type: Number,
      min: 0,
      max: 1,
      default: 0
    },
    Satisfacción: {
      type: Number,
      min: 0,
      max: 1,
      default: 0
    }
  },
  imageUrl: {
    type: String,
    default: 'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800'
  },
  supervisor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  team: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Project', projectSchema);