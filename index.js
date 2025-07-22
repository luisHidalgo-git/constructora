const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const app = express();

// Configuración de puerto para Railway
const PORT = process.env.PORT || 3000;

console.log('🔧 Starting server configuration...');
console.log('🔧 PORT:', PORT);
console.log('🔧 NODE_ENV:', process.env.NODE_ENV);
console.log('🔧 MONGODB_URI exists:', !!process.env.MONGODB_URI);

// Middleware CORS más permisivo para Railway
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'User-Agent', 'Cache-Control', 'Connection'],
  credentials: false
}));

// Middleware para parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Middleware para logging de requests
app.use((req, res, next) => {
  console.log(`📝 ${req.method} ${req.path} - ${new Date().toISOString()}`);
  if (req.body && Object.keys(req.body).length > 0) {
    const logBody = { ...req.body };
    if (logBody.password) logBody.password = '[HIDDEN]';
    console.log('📝 Request body:', logBody);
  }
  next();
});

// Servir archivos estáticos (imágenes subidas)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Conexión a MongoDB con configuración para Railway
const connectDB = async () => {
  try {
    const mongoUri = process.env.MONGODB_URI;
    if (!mongoUri) {
      throw new Error('MONGODB_URI no está definida en las variables de entorno');
    }

    console.log('🔍 Connecting to MongoDB...');
    
    await mongoose.connect(mongoUri, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 30000,
      socketTimeoutMS: 45000,
      maxPoolSize: 10,
      retryWrites: true,
      w: 'majority'
    });

    console.log('✅ Conectado a MongoDB exitosamente');
  } catch (error) {
    console.error('❌ Error conectando a MongoDB:', error.message);
    console.error('❌ Stack:', error.stack);
    
    // En Railway, intentar reconectar después de un delay
    setTimeout(() => {
      console.log('🔄 Intentando reconectar a MongoDB...');
      connectDB();
    }, 5000);
  }
};

// Conectar a la base de datos
connectDB();

// Manejar eventos de conexión de MongoDB
mongoose.connection.on('connected', () => {
  console.log('✅ MongoDB conectado');
});

mongoose.connection.on('error', (err) => {
  console.error('❌ Error de MongoDB:', err);
});

mongoose.connection.on('disconnected', () => {
  console.log('⚠️ MongoDB desconectado');
});

// Rutas básicas
app.get('/', (req, res) => {
  res.json({
    message: 'API Constructora - Avanze 360',
    version: '1.0.0',
    status: 'running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    port: PORT
  });
});

// Health check mejorado
app.get('/health', (req, res) => {
  const dbStatus = mongoose.connection.readyState;
  const dbStatusText = {
    0: 'disconnected',
    1: 'connected',
    2: 'connecting',
    3: 'disconnecting'
  }[dbStatus] || 'unknown';

  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    database: dbStatusText,
    port: PORT,
    environment: process.env.NODE_ENV || 'development',
    uptime: process.uptime()
  });
});

// Importar y usar rutas
try {
  app.use('/api/auth', require('./routes/auth'));
  app.use('/api/projects', require('./routes/projects'));
  app.use('/api/activities', require('./routes/activities'));
  app.use('/api/stats', require('./routes/stats'));
  app.use('/api/upload', require('./routes/upload'));
  app.use('/api/tv-auth', require('./routes/tv-auth'));
  console.log('✅ Rutas cargadas exitosamente');
} catch (error) {
  console.error('❌ Error cargando rutas:', error);
}

// Middleware de manejo de errores
app.use((err, req, res, next) => {
  console.error('❌ Error en middleware:', err.stack);
  res.status(500).json({
    message: 'Error interno del servidor',
    error: process.env.NODE_ENV === 'development' ? err.message : 'Error interno',
    timestamp: new Date().toISOString()
  });
});

// Ruta 404
app.use('*', (req, res) => {
  console.log(`❌ Ruta no encontrada: ${req.method} ${req.originalUrl}`);
  res.status(404).json({
    message: 'Ruta no encontrada',
    path: req.originalUrl,
    method: req.method,
    timestamp: new Date().toISOString()
  });
});

// Manejar señales de terminación para Railway
process.on('SIGTERM', () => {
  console.log('🔄 SIGTERM recibido, cerrando servidor...');
  mongoose.connection.close(() => {
    console.log('✅ Conexión a MongoDB cerrada');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('🔄 SIGINT recibido, cerrando servidor...');
  mongoose.connection.close(() => {
    console.log('✅ Conexión a MongoDB cerrada');
    process.exit(0);
  });
});

// Iniciar servidor
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log('🚀 Servidor iniciado exitosamente');
  console.log(`📱 API disponible en puerto: ${PORT}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
  console.log(`📊 Rutas disponibles:`);
  console.log(`   • /api/auth`);
  console.log(`   • /api/projects`);
  console.log(`   • /api/activities`);
  console.log(`   • /api/stats`);
  console.log(`   • /api/upload`);
});

// Manejar errores del servidor
server.on('error', (error) => {
  console.error('❌ Error del servidor:', error);
});

module.exports = app;