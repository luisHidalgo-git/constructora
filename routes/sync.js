const express = require('express');
const { auth } = require('../middleware/auth');

const router = express.Router();

// Almacén temporal de eventos por usuario
const userEvents = new Map();

// @route   POST /api/sync/navigation
// @desc    Send navigation event
// @access  Private
router.post('/navigation', auth, async (req, res) => {
  try {
    const { eventType, data, timestamp } = req.body;
    const userId = req.user.id;

    console.log(`🔄 Navigation event from ${req.user.email}: ${eventType} at ${new Date().toISOString()}`);

    // Crear evento
    const event = {
      id: Date.now().toString(),
      userId,
      eventType,
      data: data || {},
      timestamp: timestamp || new Date().toISOString(),
      processed: false,
      createdAt: new Date().toISOString(),
    };

    // Almacenar evento para el usuario
    if (!userEvents.has(userId)) {
      userEvents.set(userId, []);
    }
    
    const events = userEvents.get(userId);
    events.push(event);

    // Mantener solo los últimos 20 eventos y limpiar eventos antiguos
    const now = new Date();
    const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);
    
    // Filtrar eventos antiguos
    const recentEvents = events.filter(event => {
      const eventTime = new Date(event.createdAt);
      return eventTime > oneHourAgo;
    });
    
    // Mantener solo los últimos 20
    if (recentEvents.length > 20) {
      recentEvents.splice(0, recentEvents.length - 20);
    }
    
    userEvents.set(userId, recentEvents);

    console.log(`✅ Event stored for user ${userId}: ${eventType} (${recentEvents.length} total events)`);

    res.json({
      success: true,
      message: 'Navigation event sent',
      eventId: event.id,
      totalEvents: recentEvents.length,
    });

  } catch (error) {
    console.error('❌ Error sending navigation event:', error);
    res.status(500).json({
      message: 'Error sending navigation event',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   GET /api/sync/navigation
// @desc    Get navigation events for user
// @access  Private
router.get('/navigation', auth, async (req, res) => {
  try {
    const userId = req.user.id;

    if (!userEvents.has(userId)) {
      return res.json({
        hasEvents: false,
        events: [],
        timestamp: new Date().toISOString(),
      });
    }

    const events = userEvents.get(userId);
    
    // Limpiar eventos antiguos antes de procesar
    const now = new Date();
    const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);
    const recentEvents = events.filter(event => {
      const eventTime = new Date(event.createdAt);
      return eventTime > oneHourAgo;
    });
    
    userEvents.set(userId, recentEvents);
    
    const unprocessedEvents = events.filter(event => !event.processed);

    if (unprocessedEvents.length === 0) {
      return res.json({
        hasEvents: false,
        events: [],
        timestamp: new Date().toISOString(),
      });
    }

    // Marcar eventos como procesados
    unprocessedEvents.forEach(event => {
      event.processed = true;
      event.processedAt = new Date().toISOString();
    });

    console.log(`📨 Sending ${unprocessedEvents.length} events to user ${userId} at ${new Date().toISOString()}`);

    res.json({
      hasEvents: true,
      events: unprocessedEvents,
      timestamp: new Date().toISOString(),
      totalEvents: recentEvents.length,
    });

  } catch (error) {
    console.error('❌ Error getting navigation events:', error);
    res.status(500).json({
      message: 'Error getting navigation events',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   DELETE /api/sync/navigation
// @desc    Clear navigation events for user
// @access  Private
router.delete('/navigation', auth, async (req, res) => {
  try {
    const userId = req.user.id;
    
    if (userEvents.has(userId)) {
      userEvents.delete(userId);
      console.log(`🗑️ Cleared events for user ${userId} at ${new Date().toISOString()}`);
    }

    res.json({
      success: true,
      message: 'Navigation events cleared',
      timestamp: new Date().toISOString(),
    });

  } catch (error) {
    console.error('❌ Error clearing navigation events:', error);
    res.status(500).json({
      message: 'Error clearing navigation events',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   GET /api/sync/status
// @desc    Get sync status for debugging
// @access  Private
router.get('/status', auth, async (req, res) => {
  try {
    const userId = req.user.id;
    const userEventCount = userEvents.has(userId) ? userEvents.get(userId).length : 0;
    const totalUsers = userEvents.size;
    
    res.json({
      success: true,
      userId: userId,
      userEventCount: userEventCount,
      totalUsers: totalUsers,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('❌ Error getting sync status:', error);
    res.status(500).json({
      message: 'Error getting sync status',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

module.exports = router;