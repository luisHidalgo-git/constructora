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
    console.log('🔍 Upload request received');
    console.log('🔍 Request file:', req.file);

    if (!req.file) {
      console.log('❌ No file received in request');
      return res.status(400).json({ message: 'No se ha subido ningún archivo' });
    }

    const filePath = req.file.path;
    const filename = req.file.filename;

    console.log('📁 Archivo guardado en:', filePath);
    console.log('📁 Archivo existe:', fs.existsSync(filePath));

    // Verificar que el archivo realmente se guardó
    if (!fs.existsSync(filePath)) {
      console.log('❌ El archivo no se guardó en el sistema de archivos');
      return res.status(500).json({ message: 'Error: El archivo no se guardó correctamente' });
    }

    const fileStats = fs.statSync(filePath);
    console.log('📁 Tamaño del archivo en disco:', fileStats.size, 'bytes');

    console.log('📁 Imagen subida exitosamente:', {
      filename: filename,
      originalName: req.file.originalname,
      size: req.file.size,
      mimetype: req.file.mimetype,
      path: filePath,
      user: req.user.email
    });

    // Construir URL completa de la imagen
    const protocol = req.get('x-forwarded-proto') || req.protocol;
    const host = req.get('host');
    
    // Para Railway, usar HTTPS siempre
    const imageUrl = `https://${host}/uploads/${filename}`;

    console.log('🔗 URL de imagen generada:', imageUrl);
    console.log('✅ Imagen guardada exitosamente en el servidor');
    
    res.json({
      message: 'Imagen subida automáticamente al servidor',
      imageUrl: imageUrl,
      filename: filename,
      originalName: req.file.originalname,
      size: req.file.size,
      mimetype: req.file.mimetype,
      uploadedAt: new Date().toISOString(),
      uploadedBy: req.user.email,
      success: true
    });

  } catch (error) {
    console.error('❌ Error uploading image:', error);
    res.status(500).json({ 
      message: 'Error del servidor al subir la imagen',
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
    console.log('🗑️ File path:', filePath);

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
      console.log('❌ Image not found for deletion:', filename);
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
    
    console.log('🔍 Listing images in:', uploadsDir);
    
    if (!fs.existsSync(uploadsDir)) {
      console.log('❌ Uploads directory does not exist');
      return res.json({ images: [] });
    }

    const files = fs.readdirSync(uploadsDir);
    console.log('🔍 Files found:', files.length);

    const imageFiles = files.filter(file => {
      const ext = path.extname(file).toLowerCase();
      return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext);
    });

    console.log('🔍 Image files found:', imageFiles.length);

    const protocol = req.get('x-forwarded-proto') || req.protocol;
    const host = req.get('host');

    const images = imageFiles.map(filename => {
      const filePath = path.join(uploadsDir, filename);
      const stats = fs.statSync(filePath);
      return {
        filename,
        url: `${protocol}://${host}/uploads/${filename}`,
        size: stats.size,
        uploadedAt: stats.birthtime,
        modifiedAt: stats.mtime
      };
    });

    res.json({
      message: 'Lista de imágenes en el servidor',
      count: images.length,
      uploadsDir: uploadsDir,
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