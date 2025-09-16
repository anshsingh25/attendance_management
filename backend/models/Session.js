const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
  class: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Class',
    required: [true, 'Class is required']
  },
  teacher: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Teacher is required']
  },
  date: {
    type: Date,
    required: [true, 'Session date is required']
  },
  startTime: {
    type: Date,
    required: [true, 'Start time is required']
  },
  endTime: {
    type: Date,
    required: [true, 'End time is required']
  },
  qrCode: {
    data: {
      type: String,
      required: true
    },
    expiresAt: {
      type: Date,
      required: true
    },
    isActive: {
      type: Boolean,
      default: true
    }
  },
  status: {
    type: String,
    enum: ['scheduled', 'active', 'completed', 'cancelled'],
    default: 'scheduled'
  },
  allowWifiAutoMark: {
    type: Boolean,
    default: false
  },
  attendanceWindow: {
    start: {
      type: Date,
      required: true
    },
    end: {
      type: Date,
      required: true
    }
  },
  totalStudents: {
    type: Number,
    default: 0
  },
  presentCount: {
    type: Number,
    default: 0
  },
  lateCount: {
    type: Number,
    default: 0
  },
  absentCount: {
    type: Number,
    default: 0
  },
  notes: {
    type: String,
    trim: true,
    maxlength: [1000, 'Notes cannot be more than 1000 characters']
  }
}, {
  timestamps: true
});

// Index for better query performance
sessionSchema.index({ class: 1, date: -1 });
sessionSchema.index({ teacher: 1, date: -1 });
sessionSchema.index({ status: 1 });
sessionSchema.index({ 'qrCode.expiresAt': 1 });

// Virtual for attendance percentage
sessionSchema.virtual('attendancePercentage').get(function() {
  if (this.totalStudents === 0) return 0;
  return Math.round(((this.presentCount + this.lateCount) / this.totalStudents) * 100);
});

// Ensure virtual fields are serialized
sessionSchema.set('toJSON', { virtuals: true });

// Pre-save middleware to update counts
sessionSchema.pre('save', async function(next) {
  if (this.isModified('status') && this.status === 'completed') {
    // Update attendance counts when session is completed
    const Attendance = mongoose.model('Attendance');
    const counts = await Attendance.aggregate([
      { $match: { session: this._id } },
      { $group: { 
        _id: '$status', 
        count: { $sum: 1 } 
      }}
    ]);
    
    this.presentCount = counts.find(c => c._id === 'present')?.count || 0;
    this.lateCount = counts.find(c => c._id === 'late')?.count || 0;
    this.absentCount = counts.find(c => c._id === 'absent')?.count || 0;
  }
  next();
});

module.exports = mongoose.model('Session', sessionSchema);
