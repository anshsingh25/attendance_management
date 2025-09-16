const mongoose = require('mongoose');

const geoPointSchema = new mongoose.Schema({
  latitude: {
    type: Number,
    required: true,
    min: -90,
    max: 90
  },
  longitude: {
    type: Number,
    required: true,
    min: -180,
    max: 180
  }
}, { _id: false });

const geoBoundsSchema = new mongoose.Schema({
  southwest: {
    type: geoPointSchema,
    required: true
  },
  northeast: {
    type: geoPointSchema,
    required: true
  }
}, { _id: false });

const campusSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Campus name is required'],
    trim: true,
    maxlength: [100, 'Campus name cannot be more than 100 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [500, 'Description cannot be more than 500 characters']
  },
  boundaryType: {
    type: String,
    enum: ['circle', 'polygon', 'rectangle'],
    default: 'circle'
  },
  center: {
    type: geoPointSchema,
    required: true
  },
  radius: {
    type: Number,
    min: [1, 'Radius must be at least 1 meter'],
    max: [10000, 'Radius cannot exceed 10km'],
    default: 0
  },
  polygonPoints: [{
    type: geoPointSchema
  }],
  bounds: {
    type: geoBoundsSchema,
    required: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  lastUsed: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Index for better query performance
campusSchema.index({ center: '2dsphere' });
campusSchema.index({ isActive: 1 });
campusSchema.index({ createdBy: 1 });

// Virtual for boundary area calculation
campusSchema.virtual('area').get(function() {
  switch (this.boundaryType) {
    case 'circle':
      return Math.PI * Math.pow(this.radius, 2);
    case 'rectangle':
      const latDiff = this.bounds.northeast.latitude - this.bounds.southwest.latitude;
      const lngDiff = this.bounds.northeast.longitude - this.bounds.southwest.longitude;
      // Approximate area calculation (not precise for large areas)
      return latDiff * lngDiff * 111000 * 111000; // Rough conversion to square meters
    case 'polygon':
      // Complex polygon area calculation would go here
      return 0;
    default:
      return 0;
  }
});

// Method to check if a point is inside the campus boundary
campusSchema.methods.isPointInside = function(latitude, longitude) {
  switch (this.boundaryType) {
    case 'circle':
      return this.isPointInCircle(latitude, longitude);
    case 'polygon':
      return this.isPointInPolygon(latitude, longitude);
    case 'rectangle':
      return this.isPointInRectangle(latitude, longitude);
    default:
      return false;
  }
};

// Check if point is inside circle
campusSchema.methods.isPointInCircle = function(latitude, longitude) {
  const R = 6371e3; // Earth's radius in meters
  const φ1 = this.center.latitude * Math.PI / 180;
  const φ2 = latitude * Math.PI / 180;
  const Δφ = (latitude - this.center.latitude) * Math.PI / 180;
  const Δλ = (longitude - this.center.longitude) * Math.PI / 180;

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) *
    Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  const distance = R * c; // Distance in meters
  return distance <= this.radius;
};

// Check if point is inside polygon
campusSchema.methods.isPointInPolygon = function(latitude, longitude) {
  if (this.polygonPoints.length < 3) return false;

  let inside = false;
  let j = this.polygonPoints.length - 1;

  for (let i = 0; i < this.polygonPoints.length; i++) {
    const xi = this.polygonPoints[i].latitude;
    const yi = this.polygonPoints[i].longitude;
    const xj = this.polygonPoints[j].latitude;
    const yj = this.polygonPoints[j].longitude;

    if (((yi > latitude) !== (yj > latitude)) &&
        (longitude < (xj - xi) * (latitude - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
    j = i;
  }

  return inside;
};

// Check if point is inside rectangle
campusSchema.methods.isPointInRectangle = function(latitude, longitude) {
  return latitude >= this.bounds.southwest.latitude &&
         latitude <= this.bounds.northeast.latitude &&
         longitude >= this.bounds.southwest.longitude &&
         longitude <= this.bounds.northeast.longitude;
};

// Method to calculate distance to campus center
campusSchema.methods.distanceToCenter = function(latitude, longitude) {
  const R = 6371e3; // Earth's radius in meters
  const φ1 = this.center.latitude * Math.PI / 180;
  const φ2 = latitude * Math.PI / 180;
  const Δφ = (latitude - this.center.latitude) * Math.PI / 180;
  const Δλ = (longitude - this.center.longitude) * Math.PI / 180;

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) *
    Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Distance in meters
};

// Method to get boundary info for frontend
campusSchema.methods.getBoundaryInfo = function() {
  return {
    id: this._id,
    name: this.name,
    description: this.description,
    boundaryType: this.boundaryType,
    center: this.center,
    radius: this.radius,
    polygonPoints: this.polygonPoints,
    bounds: this.bounds,
    isActive: this.isActive,
    area: this.area,
    createdBy: this.createdBy,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

// Pre-save middleware to validate boundary data
campusSchema.pre('save', function(next) {
  // Validate polygon points
  if (this.boundaryType === 'polygon' && this.polygonPoints.length < 3) {
    return next(new Error('Polygon must have at least 3 points'));
  }

  // Validate circle radius
  if (this.boundaryType === 'circle' && this.radius <= 0) {
    return next(new Error('Circle radius must be greater than 0'));
  }

  // Validate rectangle bounds
  if (this.boundaryType === 'rectangle') {
    if (this.bounds.southwest.latitude >= this.bounds.northeast.latitude ||
        this.bounds.southwest.longitude >= this.bounds.northeast.longitude) {
      return next(new Error('Invalid rectangle bounds'));
    }
  }

  next();
});

module.exports = mongoose.model('Campus', campusSchema);
