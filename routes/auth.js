const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const generateToken = require('../utils/generateToken');
const { auth } = require('../middleware/auth');

const router = express.Router();

// @route   POST /api/auth/register
// @desc    Register a new user (Admin only - for Postman)
// @access  Public (but intended for admin use)
router.post('/register', [
  body('name', 'El nombre es requerido').not().isEmpty(),
  body('email', 'Por favor incluye un email válido').isEmail(),
  body('password', 'La contraseña debe tener al menos 6 caracteres').isLength({ min: 6 }),
  body('role', 'El rol debe ser admin, supervisor o worker').optional().isIn(['admin', 'supervisor', 'worker']),
  body('position', 'La posición debe ser válida').optional().isLength({ max: 100 })
], async (req, res) => {
  try {
    console.log('🔍 Registro - Request recibido:', {
      body: { ...req.body, password: '[HIDDEN]' },
      headers: req.headers,
      ip: req.ip
    });

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('❌ Errores de validación:', errors.array());
      return res.status(400).json({ 
        message: 'Datos de entrada inválidos',
        errors: errors.array() 
      });
    }

    const { name, email, password, role, position } = req.body;

    // Validar que el email no esté vacío después del trim
    if (!email || email.trim() === '') {
      return res.status(400).json({ message: 'El email es requerido' });
    }

    // Validar que el nombre no esté vacío después del trim
    if (!name || name.trim() === '') {
      return res.status(400).json({ message: 'El nombre es requerido' });
    }

    // Validar longitud de contraseña
    if (!password || password.length < 6) {
      return res.status(400).json({ message: 'La contraseña debe tener al menos 6 caracteres' });
    }

    // Check if user exists
    let user = await User.findOne({ email: email.toLowerCase().trim() });
    if (user) {
      console.log('❌ Usuario ya existe:', email);
      return res.status(400).json({ message: 'El usuario ya existe' });
    }

    console.log('🔍 Creando nuevo usuario:', {
      name: name.trim(),
      email: email.toLowerCase().trim(),
      role: role || 'supervisor'
    });

    // Create user
    user = new User({
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password,
      role: role || 'supervisor',
      position: position?.trim() || 'Supervisor'
    });

    await user.save();
    console.log('✅ Usuario guardado en BD:', user.id);

    // Generate token
    const token = generateToken(user.id);
    console.log('✅ Token generado para usuario:', user.id);

    console.log('✅ Usuario creado exitosamente:', {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role
    });

    res.status(201).json({
      message: 'Usuario creado exitosamente',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        position: user.position
      }
    });

  } catch (error) {
    console.error('❌ Error en registro:', error.message);
    console.error('Stack trace:', error.stack);
    
    // Manejar errores específicos de MongoDB
    if (error.code === 11000) {
      return res.status(400).json({ message: 'El email ya está registrado' });
    }
    
    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({ message: messages.join(', ') });
    }
    
    res.status(500).json({ 
      message: 'Error interno del servidor',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Error interno'
    });
  }
});

// @route   POST /api/auth/login
// @desc    Login user
// @access  Public
router.post('/login', [
  body('email', 'Por favor incluye un email válido').isEmail(),
  body('password', 'La contraseña es requerida').exists()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        message: 'Datos de entrada inválidos',
        errors: errors.array() 
      });
    }

    const { email, password } = req.body;

    // Validaciones adicionales
    if (!email || email.trim() === '') {
      return res.status(400).json({ message: 'El email es requerido' });
    }

    if (!password) {
      return res.status(400).json({ message: 'La contraseña es requerida' });
    }

    // Check if user exists
    const user = await User.findOne({ email: email.toLowerCase().trim() });
    if (!user) {
      return res.status(400).json({ message: 'Credenciales inválidas' });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(400).json({ message: 'Usuario inactivo. Contacta al administrador.' });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Credenciales inválidas' });
    }

    // Update last login
    user.lastLogin = new Date();
    await user.save();

    // Generate token
    const token = generateToken(user.id);

    console.log('✅ Login exitoso:', {
      id: user.id,
      email: user.email,
      name: user.name
    });

    res.json({
      message: 'Login exitoso',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        position: user.position,
        lastLogin: user.lastLogin
      }
    });

  } catch (error) {
    console.error('❌ Error en login:', error.message);
    console.error('Stack trace:', error.stack);
    res.status(500).json({ message: 'Error del servidor' });
  }
});

// @route   GET /api/auth/me
// @desc    Get current user
// @access  Private
router.get('/me', auth, async (req, res) => {
  try {
    res.json(req.user);
  } catch (error) {
    console.error(error.message);
    res.status(500).json({ message: 'Error del servidor' });
  }
});

module.exports = router;