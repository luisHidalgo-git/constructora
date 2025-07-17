const express = require('express');
const { body, validationResult } = require('express-validator');
const Project = require('../models/Project');
const { auth, authorize } = require('../middleware/auth');

const router = express.Router();

// @route   GET /api/projects
// @desc    Get all projects for current user
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const projects = await Project.find({ 
      supervisor: req.user.id,
      isActive: true 
    }).populate('supervisor', 'name email').sort({ createdAt: -1 });

    res.json(projects);
  } catch (error) {
    console.error(error.message);
    res.status(500).json({ message: 'Error del servidor' });
  }
});

// @route   GET /api/projects/:id
// @desc    Get project by ID
// @access  Private
router.get('/:id', auth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.id)
      .populate('supervisor', 'name email')
      .populate('team', 'name email');

    if (!project) {
      return res.status(404).json({ message: 'Proyecto no encontrado' });
    }

    // Check if user has access to this project
    if (project.supervisor._id.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'No tienes acceso a este proyecto' });
    }

    res.json(project);
  } catch (error) {
    console.error(error.message);
    if (error.kind === 'ObjectId') {
      return res.status(404).json({ message: 'Proyecto no encontrado' });
    }
    res.status(500).json({ message: 'Error del servidor' });
  }
});

// @route   POST /api/projects
// @desc    Create a new project
// @access  Private
router.post('/', [
  auth,
  body('name', 'El nombre del proyecto es requerido').not().isEmpty(),
  body('clientName', 'El nombre del cliente es requerido').not().isEmpty(),
  body('description', 'La descripción es requerida').not().isEmpty(),
  body('location', 'La ubicación es requerida').not().isEmpty(),
  body('budget', 'El presupuesto es requerido').not().isEmpty(),
  body('startDate', 'La fecha de inicio es requerida').not().isEmpty(),
  body('endDate', 'La fecha de fin es requerida').not().isEmpty()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const {
      name,
      clientName,
      description,
      location,
      budget,
      startDate,
      endDate,
      imageUrl
    } = req.body;

    const project = new Project({
      name,
      clientName,
      description,
      location,
      budget,
      startDate,
      endDate,
      supervisor: req.user.id,
      imageUrl: imageUrl || 'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800'
    });

    await project.save();
    await project.populate('supervisor', 'name email');

    res.status(201).json({
      message: 'Proyecto creado exitosamente',
      project
    });

  } catch (error) {
    console.error(error.message);
    res.status(500).json({ message: 'Error del servidor' });
  }
});

// @route   PUT /api/projects/:id
// @desc    Update project
// @access  Private
router.put('/:id', [
  auth,
  body('name', 'El nombre del proyecto es requerido').optional().not().isEmpty(),
  body('clientName', 'El nombre del cliente es requerido').optional().not().isEmpty(),
  body('description', 'La descripción es requerida').optional().not().isEmpty(),
  body('location', 'La ubicación es requerida').optional().not().isEmpty(),
  body('budget', 'El presupuesto es requerido').optional().not().isEmpty(),
  body('progress', 'El progreso debe ser un número entre 0 y 1').optional().isFloat({ min: 0, max: 1 }),
  body('status', 'El estado debe ser válido').optional().isIn(['Activo', 'Pausado', 'Completado', 'Cancelado'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    let project = await Project.findById(req.params.id);

    if (!project) {
      return res.status(404).json({ message: 'Proyecto no encontrado' });
    }

    // Check if user owns this project
    if (project.supervisor.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'No tienes permisos para actualizar este proyecto' });
    }

    // Update fields
    const updateFields = req.body;
    Object.keys(updateFields).forEach(key => {
      if (updateFields[key] !== undefined) {
        project[key] = updateFields[key];
      }
    });

    await project.save();
    await project.populate('supervisor', 'name email');

    res.json({
      message: 'Proyecto actualizado exitosamente',
      project
    });

  } catch (error) {
    console.error(error.message);
    if (error.kind === 'ObjectId') {
      return res.status(404).json({ message: 'Proyecto no encontrado' });
    }
    res.status(500).json({ message: 'Error del servidor' });
  }
});

// @route   DELETE /api/projects/:id
// @desc    Delete project (soft delete)
// @access  Private
router.delete('/:id', auth, async (req, res) => {
  try {
    let project = await Project.findById(req.params.id);

    if (!project) {
      return res.status(404).json({ message: 'Proyecto no encontrado' });
    }

    // Check if user owns this project
    if (project.supervisor.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'No tienes permisos para eliminar este proyecto' });
    }

    project.isActive = false;
    await project.save();

    res.json({ message: 'Proyecto eliminado exitosamente' });

  } catch (error) {
    console.error(error.message);
    if (error.kind === 'ObjectId') {
      return res.status(404).json({ message: 'Proyecto no encontrado' });
    }
    res.status(500).json({ message: 'Error del servidor' });
  }
});

module.exports = router;