const express = require('express');
const Stats = require('../models/Stats');
const Project = require('../models/Project');
const { auth } = require('../middleware/auth');

const router = express.Router();

// @route   GET /api/stats
// @desc    Get user stats
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    // Calculate real-time stats
    const projects = await Project.find({ 
      supervisor: req.user.id,
      isActive: true 
    });

    const activeProjects = projects.filter(p => p.status === 'Activo').length;
    const totalBudget = projects.reduce((sum, project) => {
      const budget = parseFloat(project.budget.replace(/[^0-9.-]+/g, ''));
      return sum + (isNaN(budget) ? 0 : budget);
    }, 0);

    const averageProgress = projects.length > 0 
      ? projects.reduce((sum, p) => sum + p.progress, 0) / projects.length 
      : 0;

    // Mock alerts for now
    const activeAlerts = Math.floor(Math.random() * 5) + 1;

    const stats = {
      activeProjects,
      activeAlerts,
      totalBudget: `$${totalBudget.toLocaleString()}`,
      averageProgress,
      lastUpdated: new Date(),
      user: req.user.id
    };

    res.json(stats);

  } catch (error) {
    console.error(error.message);
    res.status(500).json({ message: 'Error del servidor' });
  }
});

module.exports = router;