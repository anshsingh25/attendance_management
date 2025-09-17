const mongoose = require('mongoose');

const qrCodeSchema = new mongoose.Schema({
  code: {
    type: String,
    required: true,
    unique: true,
    length: 6
  },
  duration: {
    type: Number,
    required: true,
    min: 1,
    max: 120
  },
  expiresAt: {
    type: Date,
    required: true
  },
  actualExpiresAt: {
    type: Date,
    default: null
  },
  classId: {
    type: String,
    required: true,
    default: 'demo_class'
  },
  subject: {
    type: String,
    required: true,
    default: 'Demo Class'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  countdownStarted: {
    type: Boolean,
    default: false
  },
  createdBy: {
    type: String,
    required: true,
    default: 'demo_teacher'
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Index for faster queries
qrCodeSchema.index({ code: 1 });
qrCodeSchema.index({ isActive: 1, countdownStarted: 1 });
qrCodeSchema.index({ actualExpiresAt: 1 });

// Static method to find active QR codes
qrCodeSchema.statics.findActiveByCode = function(code) {
  return this.findOne({
    code: code,
    isActive: true
  });
};

// Static method to find expired codes
qrCodeSchema.statics.findExpiredCodes = function() {
  return this.find({
    isActive: true,
    countdownStarted: true,
    actualExpiresAt: { $lt: new Date() }
  });
};

// Instance method to check if code is expired
qrCodeSchema.methods.isExpired = function() {
  if (!this.countdownStarted || !this.actualExpiresAt) {
    return false;
  }
  return new Date() > this.actualExpiresAt;
};

// Instance method to start countdown
qrCodeSchema.methods.startCountdown = function() {
  if (this.countdownStarted) {
    throw new Error('Countdown already started for this QR code');
  }
  
  this.countdownStarted = true;
  this.actualExpiresAt = new Date(Date.now() + this.duration * 60 * 1000);
  this.updatedAt = new Date();
  
  return this.save();
};

// Instance method to deactivate code
qrCodeSchema.methods.deactivate = function() {
  this.isActive = false;
  this.updatedAt = new Date();
  return this.save();
};

module.exports = mongoose.model('QRCode', qrCodeSchema);
