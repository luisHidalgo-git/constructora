const mongoose = require('mongoose');

const tvSessionSchema = new mongoose.Schema({
  sessionId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  status: {
    type: String,
    enum: ['waiting', 'authenticated', 'expired'],
    default: 'waiting'
  },
  qrData: {
    type: String,
    required: true
  },
  userToken: {
    type: String,
    default: null
  },
  userData: {
    type: mongoose.Schema.Types.Mixed,
    default: null
  },
  authenticatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  createdAt: {
    type: Date,
    default: Date.now,
    expires: 1800 // 30 minutos de expiración automática
  },
  authenticatedAt: {
    type: Date,
    default: null
  },
  ipAddress: {
    type: String,
    default: null
  },
  userAgent: {
    type: String,
    default: null
  }
}, {
  timestamps: true
});

// Índice para limpiar sesiones expiradas automáticamente
tvSessionSchema.index({ createdAt: 1 }, { expireAfterSeconds: 1800 });

// Método para verificar si la sesión ha expirado
tvSessionSchema.methods.isExpired = function() {
  const now = new Date();
  const expirationTime = new Date(this.createdAt.getTime() + (30 * 60 * 1000)); // 30 minutos
  return now > expirationTime;
};

// Método para marcar como autenticada
tvSessionSchema.methods.authenticate = function(userToken, userData, userId) {
  this.status = 'authenticated';
  this.userToken = userToken;
  this.userData = userData;
  this.authenticatedBy = userId;
  this.authenticatedAt = new Date();
  return this.save();
};

module.exports = mongoose.model('TVSession', tvSessionSchema);