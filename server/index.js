const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

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
    status: 'running'
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
    server_url: `http://localhost:${PORT}`
  });
});

// Importar rutas (se agregarán después)
app.use('/api/auth', require('./routes/auth'));
app.use('/api/projects', require('./routes/projects'));
app.use('/api/activities', require('./routes/activities'));
app.use('/api/stats', require('./routes/stats'));

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
  console.log(`🚀 Servidor corriendo en puerto ${PORT}`);
  console.log(`📱 API disponible en: http://localhost:${PORT}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
  console.log(`📊 Rutas disponibles:`);
  console.log(`   • http://localhost:${PORT}/api/auth`);
  console.log(`   • http://localhost:${PORT}/api/projects`);
  console.log(`   • http://localhost:${PORT}/api/activities`);
  console.log(`   • http://localhost:${PORT}/api/stats`);
});