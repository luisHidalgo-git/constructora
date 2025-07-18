const express = require('express');
const upload = require('../middleware/upload');
const { auth } = require('../middleware/auth');
const path = require('path');

const router = express.Router();

// @route   POST /api/upload/image
// @desc    Upload project image
// @access  Private
router.post('/image', auth, upload.single('image'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No se ha subido ningún archivo' });
    }

    // Construir URL completa de la imagen
    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

    res.json({
      message: 'Imagen subida exitosamente',
      imageUrl: imageUrl,
      filename: req.file.filename,
      originalName: req.file.originalname,
      size: req.file.size
    });

  } catch (error) {
    console.error('Error uploading image:', error);
    res.status(500).json({ message: 'Error del servidor al subir la imagen' });
  }
});

// @route   DELETE /api/upload/image/:filename
// @desc    Delete project image
// @access  Private
router.delete('/image/:filename', auth, (req, res) => {
  try {
    const filename = req.params.filename;
    const filePath = path.join(__dirname, '../uploads', filename);

    // Verificar si el archivo existe
    if (require('fs').existsSync(filePath)) {
      require('fs').unlinkSync(filePath);
      res.json({ message: 'Imagen eliminada exitosamente' });
    } else {
      res.status(404).json({ message: 'Imagen no encontrada' });
    }

  } catch (error) {
    console.error('Error deleting image:', error);
    res.status(500).json({ message: 'Error del servidor al eliminar la imagen' });
  }
});

module.exports = router;