const express = require('express');
const upload = require('../middleware/upload');
const { auth } = require('../middleware/auth');
const path = require('path');
const fs = require('fs');

const router = express.Router();

// @route   POST /api/upload/image
// @desc    Upload project image automatically
// @access  Private
router.post('/image', auth, upload.single('image'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No se ha subido ningún archivo' });
    }

    console.log('📁 Image uploaded automatically:', {
      filename: req.file.filename,
      originalName: req.file.originalname,
      size: req.file.size,
      mimetype: req.file.mimetype,
      path: req.file.path,
      user: req.user.email
    });

    // Construir URL completa de la imagen
    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

    console.log('🔗 Generated image URL:', imageUrl);
    console.log('✅ Image successfully stored on server filesystem');
    
    res.json({
      message: 'Imagen subida automáticamente al servidor',
      imageUrl: imageUrl,
      filename: req.file.filename,
      originalName: req.file.originalname,
      size: req.file.size,
      mimetype: req.file.mimetype,
      uploadedAt: new Date().toISOString(),
      uploadedBy: req.user.email
    });

  } catch (error) {
    console.error('❌ Error uploading image automatically:', error);
    res.status(500).json({ 
      message: 'Error del servidor al subir la imagen automáticamente',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Error interno'
    });
  }
});

// @route   DELETE /api/upload/image/:filename
// @desc    Delete project image from server
// @access  Private
router.delete('/image/:filename', auth, (req, res) => {
  try {
    const filename = req.params.filename;
    const filePath = path.join(__dirname, '../uploads', filename);

    console.log('🗑️ Attempting to delete image:', filename);

    // Verificar si el archivo existe
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
      console.log('✅ Image deleted successfully:', filename);
      res.json({ 
        message: 'Imagen eliminada exitosamente del servidor',
        filename: filename,
        deletedAt: new Date().toISOString(),
        deletedBy: req.user.email
      });
    } else {
      console.log('❌ Image not found:', filename);
      res.status(404).json({ message: 'Imagen no encontrada en el servidor' });
    }

  } catch (error) {
    console.error('❌ Error deleting image:', error);
    res.status(500).json({ 
      message: 'Error del servidor al eliminar la imagen',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Error interno'
    });
  }
});

// @route   GET /api/upload/images
// @desc    List all uploaded images for current user (optional endpoint)
// @access  Private
router.get('/images', auth, (req, res) => {
  try {
    const uploadsDir = path.join(__dirname, '../uploads');
    
    if (!fs.existsSync(uploadsDir)) {
      return res.json({ images: [] });
    }

    const files = fs.readdirSync(uploadsDir);
    const imageFiles = files.filter(file => {
      const ext = path.extname(file).toLowerCase();
      return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext);
    });

    const images = imageFiles.map(filename => {
      const filePath = path.join(uploadsDir, filename);
      const stats = fs.statSync(filePath);
      return {
        filename,
        url: `${req.protocol}://${req.get('host')}/uploads/${filename}`,
        size: stats.size,
        uploadedAt: stats.birthtime,
        modifiedAt: stats.mtime
      };
    });

    res.json({
      message: 'Lista de imágenes en el servidor',
      count: images.length,
      images: images.sort((a, b) => new Date(b.uploadedAt) - new Date(a.uploadedAt))
    });

  } catch (error) {
    console.error('❌ Error listing images:', error);
    res.status(500).json({ 
      message: 'Error del servidor al listar imágenes',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Error interno'
    });
  }
});

module.exports = router;