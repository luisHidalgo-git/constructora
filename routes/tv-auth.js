const express = require('express');
const { body, validationResult } = require('express-validator');
const TVSession = require('../models/TVSession');
const User = require('../models/User');
const { auth } = require('../middleware/auth');
const crypto = require('crypto');

const router = express.Router();

// @route   POST /api/tv-auth/create-session
// @desc    Crear una nueva sesión de TV
// @access  Public (para la TV)
router.post('/create-session', async (req, res) => {
  try {
    // Generar un ID de sesión único
    const sessionId = crypto.randomBytes(16).toString('hex').toUpperCase();
    
    // Crear datos del QR
    const qrData = JSON.stringify({
      type: 'tv_login',
      sessionId: sessionId,
      timestamp: Date.now(),
      appName: 'Avanze360',
      version: '1.0.0'
    });

    // Crear sesión en la base de datos
    const tvSession = new TVSession({
      sessionId,
      qrData,
      ipAddress: req.ip,
      userAgent: req.get('User-Agent')
    });

    await tvSession.save();

    console.log(`🔍 TV Session created: ${sessionId}`);

    res.status(201).json({
      success: true,
      sessionId,
      qrData,
      expiresAt: new Date(Date.now() + (30 * 60 * 1000)), // 30 minutos
      message: 'Sesión de TV creada exitosamente'
    });

  } catch (error) {
    console.error('Error creating TV session:', error);
    res.status(500).json({
      success: false,
      message: 'Error del servidor al crear sesión de TV'
    });
  }
});

// @route   POST /api/tv-auth/authenticate-session
// @desc    Autenticar una sesión de TV desde el móvil
// @access  Private (requiere autenticación del móvil)
router.post('/authenticate-session', [
  auth,
  body('sessionId', 'El ID de sesión es requerido').not().isEmpty()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        success: false,
        errors: errors.array() 
      });
    }

    const { sessionId } = req.body;

    // Buscar la sesión
    const tvSession = await TVSession.findOne({ sessionId });
    
    if (!tvSession) {
      return res.status(404).json({
        success: false,
        message: 'Sesión de TV no encontrada'
      });
    }

    // Verificar si la sesión ha expirado
    if (tvSession.isExpired()) {
      tvSession.status = 'expired';
      await tvSession.save();
      return res.status(400).json({
        success: false,
        message: 'La sesión de TV ha expirado'
      });
    }

    // Verificar si ya está autenticada
    if (tvSession.status === 'authenticated') {
      return res.status(400).json({
        success: false,
        message: 'La sesión ya está autenticada'
      });
    }

    // Obtener token del usuario autenticado
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    // Preparar datos del usuario para la TV
    const userData = {
      id: req.user._id,
      name: req.user.name,
      email: req.user.email,
      role: req.user.role,
      position: req.user.position,
      isActive: req.user.isActive,
      createdAt: req.user.createdAt,
      updatedAt: req.user.updatedAt
    };

    // Autenticar la sesión
    await tvSession.authenticate(token, userData, req.user._id);

    console.log(`✅ TV Session authenticated: ${sessionId} by user: ${req.user.name}`);

    res.json({
      success: true,
      message: 'Sesión de TV autenticada exitosamente',
      sessionData: {
        sessionId: tvSession.sessionId,
        status: tvSession.status,
        authenticatedAt: tvSession.authenticatedAt,
        userData: tvSession.userData
      }
    });

  } catch (error) {
    console.error('Error authenticating TV session:', error);
    res.status(500).json({
      success: false,
      message: 'Error del servidor al autenticar sesión de TV'
    });
  }
});

// @route   GET /api/tv-auth/check-session/:sessionId
// @desc    Verificar el estado de una sesión de TV
// @access  Public (para la TV)
router.get('/check-session/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;

    const tvSession = await TVSession.findOne({ sessionId })
      .populate('authenticatedBy', 'name email role position');

    if (!tvSession) {
      return res.status(404).json({
        success: false,
        message: 'Sesión no encontrada'
      });
    }

    // Verificar si ha expirado
    if (tvSession.isExpired()) {
      tvSession.status = 'expired';
      await tvSession.save();
    }

    console.log(`🔍 TV Session status check: ${sessionId} - Status: ${tvSession.status}`);

    res.json({
      success: true,
      sessionData: {
        sessionId: tvSession.sessionId,
        status: tvSession.status,
        createdAt: tvSession.createdAt,
        authenticatedAt: tvSession.authenticatedAt,
        userData: tvSession.userData,
        isExpired: tvSession.isExpired()
      }
    });

  } catch (error) {
    console.error('Error checking TV session:', error);
    res.status(500).json({
      success: false,
      message: 'Error del servidor al verificar sesión'
    });
  }
});

// @route   DELETE /api/tv-auth/clear-session/:sessionId
// @desc    Limpiar una sesión de TV
// @access  Public (para la TV)
router.delete('/clear-session/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;

    const result = await TVSession.deleteOne({ sessionId });

    if (result.deletedCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Sesión no encontrada'
      });
    }

    console.log(`🔍 TV Session cleared: ${sessionId}`);

    res.json({
      success: true,
      message: 'Sesión eliminada exitosamente'
    });

  } catch (error) {
    console.error('Error clearing TV session:', error);
    res.status(500).json({
      success: false,
      message: 'Error del servidor al limpiar sesión'
    });
  }
});

// @route   GET /api/tv-auth/active-sessions
// @desc    Obtener sesiones activas (para debugging)
// @access  Private (solo admin)
router.get('/active-sessions', auth, async (req, res) => {
  try {
    // Solo permitir a administradores
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'No tienes permisos para ver las sesiones activas'
      });
    }

    const activeSessions = await TVSession.find({
      status: { $in: ['waiting', 'authenticated'] }
    }).populate('authenticatedBy', 'name email');

    res.json({
      success: true,
      sessions: activeSessions,
      count: activeSessions.length
    });

  } catch (error) {
    console.error('Error getting active sessions:', error);
    res.status(500).json({
      success: false,
      message: 'Error del servidor'
    });
  }
});

// @route   POST /api/tv-auth/cleanup-expired
// @desc    Limpiar sesiones expiradas manualmente
// @access  Public
router.post('/cleanup-expired', async (req, res) => {
  try {
    const result = await TVSession.deleteMany({
      $or: [
        { status: 'expired' },
        { createdAt: { $lt: new Date(Date.now() - (30 * 60 * 1000)) } }
      ]
    });

    console.log(`🔍 Cleaned up ${result.deletedCount} expired TV sessions`);

    res.json({
      success: true,
      message: `${result.deletedCount} sesiones expiradas eliminadas`,
      deletedCount: result.deletedCount
    });

  } catch (error) {
    console.error('Error cleaning up expired sessions:', error);
    res.status(500).json({
      success: false,
      message: 'Error del servidor al limpiar sesiones'
    });
  }
});

module.exports = router;