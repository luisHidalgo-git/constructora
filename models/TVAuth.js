const mongoose = require('mongoose');

const tvAuthSchema = new mongoose.Schema({
  qrCode: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  isUsed: {
    type: Boolean,
    default: false
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  token: {
    type: String,
    default: null
  },
  expiresAt: {
    type: Date,
    required: true,
    index: { expireAfterSeconds: 0 }
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  usedAt: {
    type: Date,
    default: null
  }
}, {
  timestamps: true
});

// Índice para limpiar códigos expirados automáticamente
tvAuthSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('TVAuth', tvAuthSchema);