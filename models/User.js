const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'El nombre es requerido'],
    trim: true,
    maxlength: [100, 'El nombre no puede exceder 100 caracteres'],
    minlength: [2, 'El nombre debe tener al menos 2 caracteres']
  },
  email: {
    type: String,
    required: [true, 'El email es requerido'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^[^\s@]+@[^\s@]+\.[^\s@]+$/, 'Por favor ingresa un email válido'],
    index: true
  },
  password: {
    type: String,
    required: [true, 'La contraseña es requerida'],
    minlength: [6, 'La contraseña debe tener al menos 6 caracteres'],
    maxlength: [128, 'La contraseña no puede exceder 128 caracteres']
  },
  role: {
    type: String,
    enum: ['admin', 'supervisor', 'worker'],
    default: 'supervisor',
    lowercase: true
  },
  position: {
    type: String,
    default: 'Supervisor',
    trim: true,
    maxlength: [100, 'La posición no puede exceder 100 caracteres']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastLogin: {
    type: Date
  },
  profileImage: {
    type: String,
    default: null
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Índice compuesto para mejorar rendimiento
userSchema.index({ email: 1, isActive: 1 });

// Middleware para hashear la contraseña antes de guardar
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    console.log('🔐 Contraseña hasheada para usuario:', this.email);
    next();
  } catch (error) {
    console.error('❌ Error hasheando contraseña:', error);
    next(error);
  }
});

// Middleware para normalizar email antes de guardar
userSchema.pre('save', function(next) {
  if (this.email) {
    this.email = this.email.toLowerCase().trim();
  }
  if (this.name) {
    this.name = this.name.trim();
  }
  if (this.position) {
    this.position = this.position.trim();
  }
  next();
});

// Método para comparar contraseñas
userSchema.methods.comparePassword = async function(candidatePassword) {
  try {
    const isMatch = await bcrypt.compare(candidatePassword, this.password);
    console.log('🔐 Comparación de contraseña para', this.email, ':', isMatch ? '✅' : '❌');
    return isMatch;
  } catch (error) {
    console.error('❌ Error comparando contraseña:', error);
    return false;
  }
};

// Método para obtener datos públicos del usuario
userSchema.methods.toJSON = function() {
  const user = this.toObject();
  delete user.password;
  delete user.__v;
  return user;
};

// Método estático para buscar por email
userSchema.statics.findByEmail = function(email) {
  return this.findOne({ email: email.toLowerCase().trim() });
};

module.exports = mongoose.model('User', userSchema);