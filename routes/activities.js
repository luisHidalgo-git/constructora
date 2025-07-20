const express = require('express');
const { body, validationResult } = require('express-validator');
const Activity = require('../models/Activity');
const Project = require('../models/Project');
const { auth } = require('../middleware/auth');

const router = express.Router();

// @route   GET /api/activities
// @desc    Get all activities for user's projects
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const activities = await Activity.find({ 
      user: req.user.id,
      isActive: true 
    })
    .populate('project', 'name clientName')
    .populate('user', 'name email')
    .sort({ createdAt: -1 });

    res.json(activities);
  } catch (error) {
    console.error(error.message);
    res.status(500).json({ message: 'Error del servidor' });
  }
});

// @route   GET /api/activities/project/:projectId
// @desc    Get activities for specific project
// @access  Private
router.get('/project/:projectId', auth, async (req, res) => {
  try {
    // Check if user has access to this project
    const project = await Project.findById(req.params.projectId);
    if (!project) {
      return res.status(404).json({ message: 'Proyecto no encontrado' });
    }

    if (project.supervisor.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'No tienes acceso a este proyecto' });
    }

    const activities = await Activity.find({ 
      project: req.params.projectId,
      isActive: true 
    })
    .populate('user', 'name email')
    .sort({ createdAt: -1 });

    res.json(activities);
  } catch (error) {
    console.error(error.message);
    if (error.kind === 'ObjectId') {
      return res.status(404).json({ message: 'Proyecto no encontrado' });
    }
    res.status(500).json({ message: 'Error del servidor' });
  }
});

// @route   POST /api/activities
// @desc    Create a new activity
// @access  Private
router.post('/', [
  auth,
  body('title', 'El título es requerido').not().isEmpty(),
  body('project', 'El ID del proyecto es requerido').not().isEmpty(),
  body('date', 'La fecha es requerida').not().isEmpty(),
  body('type', 'El tipo debe ser válido').optional().isIn(['installation', 'review', 'completion', 'inspection', 'maintenance', 'other'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { title, description, project, date, type } = req.body;

    // Check if project exists and user has access
    const projectDoc = await Project.findById(project);
    if (!projectDoc) {
      return res.status(404).json({ message: 'Proyecto no encontrado' });
    }

    if (projectDoc.supervisor.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'No tienes acceso a este proyecto' });
    }

    const activity = new Activity({
      title,
      description,
      project,
      date,
      type: type || 'other',
      user: req.user.id
    });

    await activity.save();
    await activity.populate('project', 'name clientName');
    await activity.populate('user', 'name email');

    res.status(201).json({
      message: 'Actividad creada exitosamente',
      activity
    });

  } catch (error) {
    console.error(error.message);
    res.status(500).json({ message: 'Error del servidor' });
  }
});

// @route   PUT /api/activities/:id
// @desc    Update activity
// @access  Private
router.put('/:id', [
  auth,
  body('title', 'El título es requerido').optional().not().isEmpty(),
  body('status', 'El estado debe ser válido').optional().isIn(['pending', 'in_progress', 'completed', 'cancelled'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    let activity = await Activity.findById(req.params.id);

    if (!activity) {
      return res.status(404).json({ message: 'Actividad no encontrada' });
    }

    // Check if user owns this activity
    if (activity.user.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'No tienes permisos para actualizar esta actividad' });
    }

    // Update fields
    const updateFields = req.body;
    Object.keys(updateFields).forEach(key => {
      if (updateFields[key] !== undefined) {
        activity[key] = updateFields[key];
      }
    });

    await activity.save();
    await activity.populate('project', 'name clientName');
    await activity.populate('user', 'name email');

    res.json({
      message: 'Actividad actualizada exitosamente',
      activity
    });

  } catch (error) {
    console.error(error.message);
    if (error.kind === 'ObjectId') {
      return res.status(404).json({ message: 'Actividad no encontrada' });
    }
    res.status(500).json({ message: 'Error del servidor' });
  }
});

module.exports = router;