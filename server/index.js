const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const url = require('url');
const path = require('path');
require('dotenv').config();

const app = express();

// Extraer puerto de la URL base de la API
const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000/api';
const parsedUrl = new URL(API_BASE_URL);
const PORT = parsedUrl.port || 3000;
const API_PATH = parsedUrl.pathname || '/api';

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Servir archivos estáticos (imágenes subidas)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
// Conexión a MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log(`✅ Conectado a MongoDB`);
  })
  .catch((error) => {
    console.error('❌ Error conectando a MongoDB:', error);
  });

// Rutas básicas
app.get('/', (req, res) => {
  res.json({
    message: 'API Constructora - Avanze 360',
    version: '1.0.0',
    status: 'running',
    api_base_url: API_BASE_URL
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
    api_base_url: API_BASE_URL
  });
});

// Importar rutas (se agregarán después)
app.use(`${API_PATH}/auth`, require('./routes/auth'));
app.use(`${API_PATH}/projects`, require('./routes/projects'));
app.use(`${API_PATH}/activities`, require('./routes/activities'));
app.use(`${API_PATH}/stats`, require('./routes/stats'));
app.use(`${API_PATH}/upload`, require('./routes/upload'));
app.use(`${API_PATH}/tv-auth`, require('./routes/tv-auth'));

// Middleware de manejo de errores
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    message: 'Algo salió mal!',
    error: 'Error interno del servidor'
  });
});

// Ruta 404
app.use('*', (req, res) => {
  res.status(404).json({
    message: 'Ruta no encontrada'
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Servidor corriendo en puerto ${API_BASE_URL}`);
  console.log(`📱 API disponible en: ${API_BASE_URL}`);
  console.log(`🔗 Health check: ${API_BASE_URL}/health`);
  console.log(`📊 Rutas disponibles:`);
  console.log(`   • ${API_BASE_URL}/auth`);
  console.log(`   • ${API_BASE_URL}/projects`);
  console.log(`   • ${API_BASE_URL}/activities`);
  console.log(`   • ${API_BASE_URL}/stats`);
});