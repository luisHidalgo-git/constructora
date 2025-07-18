const express = require('express');
const QRCode = require('qrcode');
const { v4: uuidv4 } = require('uuid');
const TVSession = require('../models/TVSession');
const { auth } = require('../middleware/auth');

const router = express.Router();

// @route   POST /api/tv/generate-qr
// @desc    Generate QR code for TV authentication
// @access  Public
router.post('/generate-qr', async (req, res) => {
  try {
    const sessionId = uuidv4();
    
    // Crear datos para el QR
    const qrData = {
      type: 'tv_auth',
      sessionId: sessionId,
      timestamp: Date.now()
    };

    // Generar QR code
    const qrCodeDataURL = await QRCode.toDataURL(JSON.stringify(qrData), {
      width: 300,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });

    // Guardar sesión en BD
    const tvSession = new TVSession({
      sessionId: sessionId,
      qrCode: qrCodeDataURL
    });

    await tvSession.save();

    res.json({
      sessionId: sessionId,
      qrCode: qrCodeDataURL,
      expiresIn: 600 // 10 minutos en segundos
    });

  } catch (error) {
    console.error('Error generating QR:', error);
    res.status(500).json({ message: 'Error generando código QR' });
  }
});

// @route   POST /api/tv/connect
// @desc    Connect phone to TV session
// @access  Private
router.post('/connect', auth, async (req, res) => {
  try {
    const { sessionId } = req.body;

    if (!sessionId) {
      return res.status(400).json({ message: 'Session ID es requerido' });
    }

    // Buscar sesión activa
    const tvSession = await TVSession.findOne({
      sessionId: sessionId,
      isActive: true,
      expiresAt: { $gt: new Date() }
    });

    if (!tvSession) {
      return res.status(404).json({ message: 'Sesión no encontrada o expirada' });
    }

    if (tvSession.isConnected) {
      return res.status(400).json({ message: 'Sesión ya está conectada' });
    }

    // Conectar usuario a la sesión
    tvSession.user = req.user.id;
    tvSession.isConnected = true;
    tvSession.connectedAt = new Date();
    await tvSession.save();

    // Emitir evento de conexión via WebSocket
    const io = req.app.get('io');
    if (io) {
      io.to(`tv_${sessionId}`).emit('user_connected', {
        user: {
          id: req.user.id,
          name: req.user.name,
          email: req.user.email,
          role: req.user.role,
          position: req.user.position
        },
        connectedAt: tvSession.connectedAt
      });
    }

    res.json({
      message: 'Conectado exitosamente a la TV',
      sessionId: sessionId,
      user: {
        id: req.user.id,
        name: req.user.name,
        email: req.user.email,
        role: req.user.role,
        position: req.user.position
      }
    });

  } catch (error) {
    console.error('Error connecting to TV:', error);
    res.status(500).json({ message: 'Error conectando a la TV' });
  }
});

// @route   GET /api/tv/session/:sessionId
// @desc    Get TV session status
// @access  Public
router.get('/session/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;

    const tvSession = await TVSession.findOne({
      sessionId: sessionId,
      isActive: true
    }).populate('user', 'name email role position');

    if (!tvSession) {
      return res.status(404).json({ message: 'Sesión no encontrada' });
    }

    res.json({
      sessionId: tvSession.sessionId,
      isConnected: tvSession.isConnected,
      user: tvSession.user,
      connectedAt: tvSession.connectedAt,
      expiresAt: tvSession.expiresAt
    });

  } catch (error) {
    console.error('Error getting session:', error);
    res.status(500).json({ message: 'Error obteniendo sesión' });
  }
});

// @route   POST /api/tv/disconnect
// @desc    Disconnect from TV session
// @access  Private
router.post('/disconnect', auth, async (req, res) => {
  try {
    const { sessionId } = req.body;

    const tvSession = await TVSession.findOne({
      sessionId: sessionId,
      user: req.user.id,
      isActive: true
    });

    if (!tvSession) {
      return res.status(404).json({ message: 'Sesión no encontrada' });
    }

    // Desconectar sesión
    tvSession.isActive = false;
    await tvSession.save();

    // Emitir evento de desconexión
    const io = req.app.get('io');
    if (io) {
      io.to(`tv_${sessionId}`).emit('user_disconnected', {
        sessionId: sessionId,
        disconnectedAt: new Date()
      });
    }

    res.json({ message: 'Desconectado de la TV exitosamente' });

  } catch (error) {
    console.error('Error disconnecting from TV:', error);
    res.status(500).json({ message: 'Error desconectando de la TV' });
  }
});

module.exports = router;