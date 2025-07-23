const express = require('express');
const { v4: uuidv4 } = require('uuid');
const TVAuth = require('../models/TVAuth');
const User = require('../models/User');
const { auth } = require('../middleware/auth');

const router = express.Router();

// @route   POST /api/tv-auth/generate-qr
// @desc    Generate QR code for TV authentication
// @access  Public
router.post('/generate-qr', async (req, res) => {
  try {
    console.log('🔍 Generating new QR code for TV authentication...');

    // Generar código único
    const qrCode = uuidv4();

    // Crear registro en base de datos (expira en 2 minutos)
    const tvAuth = new TVAuth({
      qrCode,
      expiresAt: new Date(Date.now() + 2 * 60 * 1000) // 2 minutos
    });

    await tvAuth.save();

    console.log('✅ QR code generated successfully:', qrCode);

    res.json({
      qrCode,
      expiresAt: tvAuth.expiresAt,
      message: 'QR code generated successfully'
    });

  } catch (error) {
    console.error('❌ Error generating QR code:', error);
    res.status(500).json({
      message: 'Error generating QR code',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   POST /api/tv-auth/scan-qr
// @desc    Scan QR code from mobile app
// @access  Private (requires authentication)
router.post('/scan-qr', auth, async (req, res) => {
  try {
    const { qrCode } = req.body;

    console.log('🔍 Processing QR scan:', {
      qrCode,
      userId: req.user.id,
      userEmail: req.user.email
    });

    if (!qrCode) {
      return res.status(400).json({ message: 'QR code is required' });
    }

    // Buscar el código QR en la base de datos
    const tvAuth = await TVAuth.findOne({
      qrCode,
      isUsed: false,
      expiresAt: { $gt: new Date() }
    });

    if (!tvAuth) {
      console.log('❌ QR code not found or expired:', qrCode);
      return res.status(404).json({
        message: 'QR code not found or expired'
      });
    }

    // Marcar como usado y asociar con el usuario
    tvAuth.isUsed = true;
    tvAuth.user = req.user.id;
    tvAuth.usedAt = new Date();

    // Obtener el token del header de autorización
    const token = req.header('Authorization')?.replace('Bearer ', '');
    tvAuth.token = token; // Guardar el token en la base de datos

    await tvAuth.save();

    console.log('✅ QR code scanned successfully by user:', req.user.email);


    res.json({
      message: 'QR code scanned successfully',
      success: true,
      token: token, // Enviar el token a la TV
      user: {
        id: req.user.id,
        name: req.user.name,
        email: req.user.email,
        role: req.user.role,
        position: req.user.position
      }
    });

  } catch (error) {
    console.error('❌ Error scanning QR code:', error);
    res.status(500).json({
      message: 'Error scanning QR code',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   GET /api/tv-auth/check-status/:qrCode
// @desc    Check if QR code has been scanned
// @access  Public
router.get('/check-status/:qrCode', async (req, res) => {
  try {
    const { qrCode } = req.params;

    console.log('🔍 Checking QR code status:', qrCode);

    const tvAuth = await TVAuth.findOne({ qrCode }).populate('user', 'name email role position');

    if (!tvAuth) {
      return res.status(404).json({
        message: 'QR code not found',
        status: 'not_found'
      });
    }

    // Verificar si expiró
    if (tvAuth.expiresAt < new Date()) {
      return res.json({
        status: 'expired',
        message: 'QR code has expired'
      });
    }

    // Verificar si fue usado
    if (tvAuth.isUsed && tvAuth.user) {
      console.log('✅ QR code was scanned by user:', tvAuth.user.email);
      return res.json({
        status: 'authenticated',
        message: 'User authenticated successfully',
        token: tvAuth.token, // Incluir el token en la respuesta
        user: {
          id: tvAuth.user.id,
          name: tvAuth.user.name,
          email: tvAuth.user.email,
          role: tvAuth.user.role,
          position: tvAuth.user.position,
          authenticatedAt: tvAuth.usedAt
        }
      });
    }

    // Aún esperando escaneo
    res.json({
      status: 'waiting',
      message: 'Waiting for QR code to be scanned',
      expiresAt: tvAuth.expiresAt
    });

  } catch (error) {
    console.error('❌ Error checking QR status:', error);
    res.status(500).json({
      message: 'Error checking QR status',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   DELETE /api/tv-auth/cleanup
// @desc    Cleanup expired QR codes (optional maintenance endpoint)
// @access  Public
router.delete('/cleanup', async (req, res) => {
  try {
    console.log('🧹 Cleaning up expired QR codes...');

    const result = await TVAuth.deleteMany({
      expiresAt: { $lt: new Date() }
    });

    console.log(`✅ Cleaned up ${result.deletedCount} expired QR codes`);

    res.json({
      message: 'Cleanup completed',
      deletedCount: result.deletedCount
    });

  } catch (error) {
    console.error('❌ Error during cleanup:', error);
    res.status(500).json({
      message: 'Error during cleanup',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

module.exports = router;