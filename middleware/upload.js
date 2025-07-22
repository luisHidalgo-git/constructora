const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Función para crear directorio de uploads automáticamente
const createUploadsDir = () => {
  try {
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
      console.log('📁 Directorio uploads creado automáticamente en:', uploadsDir);
    }
  } catch (error) {
    console.error('❌ Error creando directorio uploads:', error);
  }
};

const uploadsDir = path.join(__dirname, '../uploads');
createUploadsDir();

// Configuración de almacenamiento
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    // Asegurar que el directorio existe antes de guardar
    createUploadsDir();
    console.log('📁 Guardando archivo en:', uploadsDir);
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    // Generar nombre único con timestamp y extensión original
    const uniqueSuffix = 'project_' + Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = path.extname(file.originalname).toLowerCase();
    const filename = uniqueSuffix + extension;
    console.log('📁 Nombre de archivo generado:', filename);
    cb(null, filename);
  }
});

// Filtro para solo permitir imágenes
const fileFilter = (req, file, cb) => {
  console.log('🔍 Verificando tipo de archivo:', file.mimetype);
  const allowedTypes = /jpeg|jpg|png|gif|webp/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);

  if (mimetype && extname) {
    console.log('✅ Tipo de archivo válido');
    return cb(null, true);
  } else {
    console.log('❌ Tipo de archivo no válido');
    cb(new Error('Solo se permiten archivos de imagen (jpeg, jpg, png, gif, webp)'));
  }
};

// Configuración de multer
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB máximo
  },
  fileFilter: fileFilter
});

module.exports = upload;