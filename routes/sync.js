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

    console.log(`🔄 Navigation event from ${req.user.email}: ${eventType}`, data ? `with data: ${JSON.stringify(data)}` : '');

    // Crear evento
    const event = {
      id: Date.now().toString(),
      userId,
      eventType,
      data: data || {},
      timestamp: timestamp || new Date().toISOString(),
      processed: false,
    };

    // Almacenar evento para el usuario
    if (!userEvents.has(userId)) {
      userEvents.set(userId, []);
    }
    
    const events = userEvents.get(userId);
    events.push(event);

    // Mantener solo los últimos 20 eventos para navegación continua
    if (events.length > 20) {
      events.splice(0, events.length - 20);
    }

    console.log(`✅ Event stored for user ${userId}: ${eventType} (total events: ${events.length})`);

    res.json({
      success: true,
      message: 'Navigation event sent',
      eventId: event.id,
      totalEvents: events.length,
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
        totalEvents: 0,
      });
    }

    const events = userEvents.get(userId);
    const unprocessedEvents = events.filter(event => !event.processed);

    if (unprocessedEvents.length === 0) {
      return res.json({
        hasEvents: false,
        events: [],
        totalEvents: events.length,
      });
    }

    // Marcar eventos como procesados
    unprocessedEvents.forEach(event => {
      event.processed = true;
    });

    console.log(`📨 Sending ${unprocessedEvents.length} unprocessed events to user ${userId} (total: ${events.length})`);

    res.json({
      hasEvents: true,
      events: unprocessedEvents,
      totalEvents: events.length,
    });

  } catch (error) {
    console.error('❌ Error getting navigation events:', error);
    res.status(500).json({
      message: 'Error getting navigation events',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   POST /api/sync/clear-processed
// @desc    Clear only processed navigation events for user
// @access  Private
router.post('/clear-processed', auth, async (req, res) => {
  try {
    const userId = req.user.id;
    
    if (userEvents.has(userId)) {
      const events = userEvents.get(userId);
      const unprocessedEvents = events.filter(event => !event.processed);
      userEvents.set(userId, unprocessedEvents);
      console.log(`🗑️ Cleared processed events for user ${userId}, kept ${unprocessedEvents.length} unprocessed`);
    }

    res.json({
      success: true,
      message: 'Processed navigation events cleared',
    });

  } catch (error) {
    console.error('❌ Error clearing processed navigation events:', error);
    res.status(500).json({
      message: 'Error clearing processed navigation events',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   DELETE /api/sync/navigation
// @desc    Clear ALL navigation events for user (for complete logout)
// @access  Private
router.delete('/navigation', auth, async (req, res) => {
  try {
    const userId = req.user.id;
    
    if (userEvents.has(userId)) {
      userEvents.delete(userId);
      console.log(`🗑️ Cleared ALL events for user ${userId}`);
    }

    res.json({
      success: true,
      message: 'All navigation events cleared',
    });

  } catch (error) {
    console.error('❌ Error clearing navigation events:', error);
    res.status(500).json({
      message: 'Error clearing navigation events',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

module.exports = router;