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

    console.log(`📱 Mobile -> Server: Navigation event from ${req.user.email}: ${eventType}`, data ? `with data: ${JSON.stringify(data)}` : '');

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

    // Mantener solo los últimos 10 eventos
    if (events.length > 10) {
      events.splice(0, events.length - 10);
    }

    console.log(`✅ Server: Event stored for user ${userId}: ${eventType} (${events.length} total events)`);

    res.json({
      success: true,
      message: 'Navigation event sent',
      eventId: event.id,
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
      });
    }

    const events = userEvents.get(userId);
    const unprocessedEvents = events.filter(event => !event.processed);

    if (unprocessedEvents.length === 0) {
      return res.json({
        hasEvents: false,
        events: [],
      });
    }

    // Marcar eventos como procesados
    unprocessedEvents.forEach(event => {
      event.processed = true;
    });

    console.log(`📺 Server -> TV: Sending ${unprocessedEvents.length} events to user ${userId}:`, unprocessedEvents.map(e => e.eventType));

    res.json({
      hasEvents: true,
      events: unprocessedEvents,
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
      console.log(`🗑️ Cleared events for user ${userId}`);
    }

    res.json({
      success: true,
      message: 'Navigation events cleared',
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