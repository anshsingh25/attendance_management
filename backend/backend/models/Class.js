const mongoose = require('mongoose');

const classSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Class name is required'],
    trim: true,
    maxlength: [100, 'Class name cannot be more than 100 characters']
  },
  code: {
    type: String,
    required: [true, 'Class code is required'],
    unique: true,
    uppercase: true,
    trim: true,
    maxlength: [20, 'Class code cannot be more than 20 characters']
  },
  subject: {
    type: String,
    required: [true, 'Subject is required'],
    trim: true
  },
  description: {
    type: String,
    trim: true,
    maxlength: [500, 'Description cannot be more than 500 characters']
  },
  teacher: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Teacher is required']
  },
  students: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  schedule: {
    days: [{
      type: String,
      enum: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
    }],
    startTime: {
      type: String,
      required: true
    },
    endTime: {
      type: String,
      required: true
    },
    room: {
      type: String,
      required: true,
      trim: true
    },
    building: {
      type: String,
      trim: true
    }
  },
  wifiSSID: {
    type: String,
    required: [true, 'WiFi SSID is required for attendance validation'],
    trim: true
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
    radius: {
      type: Number,
      default: 50 // meters
    }
  },
  isActive: {
    type: Boolean,
    default: true
  },
  semester: {
    type: String,
    required: true,
    trim: true
  },
  academicYear: {
    type: String,
    required: true,
    trim: true
  }
}, {
  timestamps: true
});

// Index for better query performance
classSchema.index({ code: 1 });
classSchema.index({ teacher: 1 });
classSchema.index({ students: 1 });
classSchema.index({ isActive: 1 });

// Virtual for student count
classSchema.virtual('studentCount').get(function() {
  return this.students.length;
});

// Ensure virtual fields are serialized
classSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('Class', classSchema);
