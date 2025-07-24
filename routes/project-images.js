const express = require('express');
const upload = require('../middleware/upload');
const { auth } = require('../middleware/auth');
const Project = require('../models/Project');
const ProjectImage = require('../models/ProjectImage');
const path = require('path');
const fs = require('fs');

const router = express.Router();

// @route   POST /api/project-images/:projectId
// @desc    Upload image to project gallery
// @access  Private
router.post('/:projectId', auth, upload.single('image'), async (req, res) => {
  try {
    const { projectId } = req.params;
    const { description } = req.body;

    console.log('🔍 Project gallery upload request:', {
      projectId,
      description,
      file: req.file ? req.file.filename : 'No file'
    });

    if (!req.file) {
      return res.status(400).json({ message: 'No se ha subido ningún archivo' });
    }

    // Verificar que el proyecto existe y el usuario tiene acceso
    const project = await Project.findById(projectId);
    if (!project) {
      return res.status(404).json({ message: 'Proyecto no encontrado' });
    }

    if (project.supervisor.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'No tienes permisos para subir imágenes a este proyecto' });
    }

    const filePath = req.file.path;
    const filename = req.file.filename;

    // Verificar que el archivo se guardó correctamente
    if (!fs.existsSync(filePath)) {
      return res.status(500).json({ message: 'Error: El archivo no se guardó correctamente' });
    }

    // Construir URL completa de la imagen
    const protocol = req.get('x-forwarded-proto') || req.protocol;
    const host = req.get('host');
    const imageUrl = process.env.NODE_ENV === 'production' 
      ? `https://${host}/uploads/${filename}`
      : `${protocol}://${host}/uploads/${filename}`;

    // Crear registro en la base de datos
    const projectImage = new ProjectImage({
      project: projectId,
      imageUrl: imageUrl,
      filename: filename,
      originalName: req.file.originalname,
      size: req.file.size,
      mimetype: req.file.mimetype,
      uploadedBy: req.user.id,
      description: description || ''
    });

    await projectImage.save();

    console.log('✅ Project image uploaded successfully:', {
      projectId,
      filename,
      imageUrl,
      uploadedBy: req.user.email
    });

    res.json({
      message: 'Imagen subida exitosamente a la galería del proyecto',
      image: {
        id: projectImage._id,
        imageUrl: imageUrl,
        filename: filename,
        originalName: req.file.originalname,
        size: req.file.size,
        mimetype: req.file.mimetype,
        description: projectImage.description,
        uploadedAt: projectImage.createdAt,
        uploadedBy: req.user.email
      },
      success: true
    });

  } catch (error) {
    console.error('❌ Error uploading project image:', error);
    res.status(500).json({ 
      message: 'Error del servidor al subir la imagen',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Error interno'
    });
  }
});

// @route   GET /api/project-images/:projectId
// @desc    Get all images for a project
// @access  Private
router.get('/:projectId', auth, async (req, res) => {
  try {
    const { projectId } = req.params;

    console.log('🔍 Getting project images for:', projectId);

    // Verificar que el proyecto existe y el usuario tiene acceso
    const project = await Project.findById(projectId);
    if (!project) {
      return res.status(404).json({ message: 'Proyecto no encontrado' });
    }

    if (project.supervisor.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'No tienes permisos para ver las imágenes de este proyecto' });
    }

    // Obtener todas las imágenes del proyecto
    const images = await ProjectImage.find({
      project: projectId,
      isActive: true
    })
    .populate('uploadedBy', 'name email')
    .sort({ createdAt: -1 });

    console.log(`✅ Found ${images.length} images for project ${projectId}`);

    res.json({
      message: 'Imágenes del proyecto obtenidas exitosamente',
      count: images.length,
      images: images.map(img => ({
        id: img._id,
        imageUrl: img.imageUrl,
        filename: img.filename,
        originalName: img.originalName,
        size: img.size,
        mimetype: img.mimetype,
        description: img.description,
        uploadedAt: img.createdAt,
        uploadedBy: {
          name: img.uploadedBy.name,
          email: img.uploadedBy.email
        }
      }))
    });

  } catch (error) {
    console.error('❌ Error getting project images:', error);
    res.status(500).json({ 
      message: 'Error del servidor al obtener las imágenes',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Error interno'
    });
  }
});

// @route   DELETE /api/project-images/:imageId
// @desc    Delete project image
// @access  Private
router.delete('/:imageId', auth, async (req, res) => {
  try {
    const { imageId } = req.params;

    console.log('🔍 Deleting project image:', imageId);

    // Buscar la imagen
    const projectImage = await ProjectImage.findById(imageId).populate('project');
    if (!projectImage) {
      return res.status(404).json({ message: 'Imagen no encontrada' });
    }

    // Verificar permisos
    if (projectImage.project.supervisor.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'No tienes permisos para eliminar esta imagen' });
    }

    // Eliminar archivo físico del servidor
    const filePath = path.join(__dirname, '../uploads', projectImage.filename);
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
      console.log('✅ Physical file deleted:', projectImage.filename);
    }

    // Marcar como inactivo en la base de datos (soft delete)
    projectImage.isActive = false;
    await projectImage.save();

    console.log('✅ Project image deleted successfully:', imageId);

    res.json({
      message: 'Imagen eliminada exitosamente de la galería del proyecto',
      deletedImage: {
        id: projectImage._id,
        filename: projectImage.filename,
        originalName: projectImage.originalName
      },
      success: true
    });

  } catch (error) {
    console.error('❌ Error deleting project image:', error);
    res.status(500).json({ 
      message: 'Error del servidor al eliminar la imagen',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Error interno'
    });
  }
});

// @route   PUT /api/project-images/:imageId
// @desc    Update project image description
// @access  Private
router.put('/:imageId', auth, async (req, res) => {
  try {
    const { imageId } = req.params;
    const { description } = req.body;

    console.log('🔍 Updating project image description:', imageId);

    // Buscar la imagen
    const projectImage = await ProjectImage.findById(imageId).populate('project');
    if (!projectImage) {
      return res.status(404).json({ message: 'Imagen no encontrada' });
    }

    // Verificar permisos
    if (projectImage.project.supervisor.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'No tienes permisos para editar esta imagen' });
    }

    // Actualizar descripción
    projectImage.description = description || '';
    await projectImage.save();

    console.log('✅ Project image description updated:', imageId);

    res.json({
      message: 'Descripción de la imagen actualizada exitosamente',
      image: {
        id: projectImage._id,
        description: projectImage.description
      },
      success: true
    });

  } catch (error) {
    console.error('❌ Error updating project image:', error);
    res.status(500).json({ 
      message: 'Error del servidor al actualizar la imagen',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Error interno'
    });
  }
});

module.exports = router;