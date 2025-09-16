const mongoose = require('mongoose');

const GeoPointSchema = new mongoose.Schema({
  latitude: {
    type: Number,
    required: true
  },
  longitude: {
    type: Number,
    required: true
  }
});

const GeoBoundsSchema = new mongoose.Schema({
  southwest: {
    type: GeoPointSchema,
    required: true
  },
  northeast: {
    type: GeoPointSchema,
    required: true
  }
});

const CampusBoundarySchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  boundaryType: {
    type: String,
    enum: ['circle', 'polygon'],
    required: true
  },
  center: {
    type: GeoPointSchema,
    required: true
  },
  radius: {
    type: Number,
    default: 0,
    min: 0
  },
  polygonPoints: [{
    type: GeoPointSchema
  }],
  bounds: {
    type: GeoBoundsSchema
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdBy: {
    type: String,
    required: true
  }
}, {
  timestamps: true
});

// Index for geospatial queries
CampusBoundarySchema.index({ center: '2dsphere' });
CampusBoundarySchema.index({ isActive: 1 });

module.exports = mongoose.model('CampusBoundary', CampusBoundarySchema);
