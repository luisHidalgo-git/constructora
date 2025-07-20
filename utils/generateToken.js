const jwt = require('jsonwebtoken');

const generateToken = (id) => {
  return jwt.sign({ id }, 'constructora_jwt_secret_2024', {
    expiresIn: '30d',
  });
};

module.exports = generateToken;