const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema({
  student: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Student is required']
  },
  class: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Class',
    required: [true, 'Class is required']
  },
  session: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Session',
    required: [true, 'Session is required']
  },
  status: {
    type: String,
    enum: ['present', 'late', 'absent', 'excused'],
    required: [true, 'Attendance status is required']
  },
  markedAt: {
    type: Date,
    default: Date.now
  },
  markedBy: {
    type: String,
    enum: ['student', 'teacher', 'system'],
    default: 'student'
  },
  location: {
    latitude: {
      type: Number,
      required: true
    },
    longitude: {
      type: Number,
      required: true
    },
    accuracy: {
      type: Number
    }
  },
  wifiSSID: {
    type: String,
    required: true
  },
  deviceInfo: {
    deviceId: String,
    platform: String,
    appVersion: String
  },
  notes: {
    type: String,
    trim: true,
    maxlength: [500, 'Notes cannot be more than 500 characters']
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  verificationMethod: {
    type: String,
    enum: ['qr_code', 'manual', 'biometric'],
    default: 'qr_code'
  }
}, {
  timestamps: true
});

// Index for better query performance
attendanceSchema.index({ student: 1, class: 1 });
attendanceSchema.index({ session: 1 });
attendanceSchema.index({ markedAt: -1 });
attendanceSchema.index({ status: 1 });

// Compound index for unique attendance per session
attendanceSchema.index({ student: 1, session: 1 }, { unique: true });

module.exports = mongoose.model('Attendance', attendanceSchema);
