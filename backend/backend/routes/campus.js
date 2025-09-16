const express = require('express');
const mongoose = require('mongoose');
const { body, param, validationResult } = require('express-validator');
const Campus = require('../models/Campus');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

// Helper function to calculate distance between two points
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Earth's radius in meters
  const φ1 = lat1 * Math.PI / 180;
  const φ2 = lat2 * Math.PI / 180;
  const Δφ = (lat2 - lat1) * Math.PI / 180;
  const Δλ = (lon2 - lon1) * Math.PI / 180;

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) *
    Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Distance in meters
}

// @desc    Get all campus boundaries (for real-time sync - only active)
// @route   GET /api/campus/boundaries/realtime
// @access  Public (for real-time sync)
router.get('/boundaries/realtime', async (req, res) => {
  try {
    const campuses = await Campus.find({ isActive: true })
      .sort({ createdAt: -1 });

    res.json(campuses); // Return direct array for real-time sync
  } catch (error) {
    console.error('Error fetching campus boundaries for real-time sync:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching campus boundaries',
      error: error.message
    });
  }
});

// @desc    Get all campus boundaries (for teacher portal - all campuses)
// @route   GET /api/campus/boundaries/all
// @access  Public (for demo purposes)
router.get('/boundaries/all', async (req, res) => {
  try {
    const campuses = await Campus.find({})
      .sort({ createdAt: -1 });

    res.json(campuses); // Return direct array for teacher portal
  } catch (error) {
    console.error('Error fetching all campus boundaries:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching campus boundaries',
      error: error.message
    });
  }
});

// @route   GET /api/campus/boundaries
// @access  Private
router.get('/boundaries', protect, async (req, res) => {
  try {
    const { isActive, createdBy } = req.query;
    
    let query = {};
    
    if (isActive !== undefined) {
      query.isActive = isActive === 'true';
    }
    
    if (createdBy) {
      query.createdBy = createdBy;
    }

    const campuses = await Campus.find(query)
      .populate('createdBy', 'name email role')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: campuses.map(campus => campus.getBoundaryInfo())
    });
  } catch (error) {
    console.error('Get campus boundaries error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching campus boundaries'
    });
  }
});

// @desc    Get campus boundary by ID
// @route   GET /api/campus/boundaries/:id
// @access  Private
router.get('/boundaries/:id', protect, [
  param('id').isMongoId().withMessage('Invalid campus ID')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const campus = await Campus.findById(req.params.id)
      .populate('createdBy', 'name email role');

    if (!campus) {
      return res.status(404).json({
        success: false,
        message: 'Campus boundary not found'
      });
    }

    res.json({
      success: true,
      data: campus.getBoundaryInfo()
    });
  } catch (error) {
    console.error('Get campus boundary error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching campus boundary'
    });
  }
});

// @desc    Create new campus boundary (Demo endpoint - no auth required)
// @route   POST /api/campus/boundaries/demo
// @access  Public (for demo purposes)
router.post('/boundaries/demo', [
  body('name').trim().isLength({ min: 2, max: 100 }).withMessage('Name must be between 2 and 100 characters'),
  body('description').optional().trim().isLength({ max: 500 }).withMessage('Description cannot exceed 500 characters'),
  body('boundaryType').isIn(['circle', 'polygon', 'rectangle']).withMessage('Invalid boundary type'),
  body('center.latitude').isFloat({ min: -90, max: 90 }).withMessage('Invalid latitude'),
  body('center.longitude').isFloat({ min: -180, max: 180 }).withMessage('Invalid longitude'),
  body('radius').optional().isFloat({ min: 1, max: 10000 }).withMessage('Radius must be between 1 and 10000 meters'),
  body('polygonPoints').optional().isArray().withMessage('Polygon points must be an array'),
  body('bounds.southwest.latitude').isFloat({ min: -90, max: 90 }).withMessage('Invalid southwest latitude'),
  body('bounds.southwest.longitude').isFloat({ min: -180, max: 180 }).withMessage('Invalid southwest longitude'),
  body('bounds.northeast.latitude').isFloat({ min: -90, max: 90 }).withMessage('Invalid northeast latitude'),
  body('bounds.northeast.longitude').isFloat({ min: -180, max: 180 }).withMessage('Invalid northeast longitude'),
  body('isActive').optional().isBoolean().withMessage('isActive must be a boolean')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { name, description, boundaryType, center, radius, polygonPoints, bounds, isActive } = req.body;

    // Check if campus with same name already exists
    const existingCampus = await Campus.findOne({ name });
    if (existingCampus) {
      return res.status(400).json({
        success: false,
        message: 'Campus boundary with this name already exists'
      });
    }

    // Validate boundary-specific requirements
    if (boundaryType === 'circle' && (!radius || radius <= 0)) {
      return res.status(400).json({
        success: false,
        message: 'Circle boundary requires a valid radius'
      });
    }

    if (boundaryType === 'polygon' && (!polygonPoints || polygonPoints.length < 3)) {
      return res.status(400).json({
        success: false,
        message: 'Polygon boundary requires at least 3 points'
      });
    }

    if (boundaryType === 'rectangle') {
      if (bounds.southwest.latitude >= bounds.northeast.latitude ||
          bounds.southwest.longitude >= bounds.northeast.longitude) {
        return res.status(400).json({
          success: false,
          message: 'Invalid rectangle bounds'
        });
      }
    }

    // Create a demo user ID for demo mode
    const demoUserId = new mongoose.Types.ObjectId();
    
    const campus = await Campus.create({
      name,
      description,
      boundaryType,
      center,
      radius: radius || 0,
      polygonPoints: polygonPoints || [],
      bounds,
      isActive: isActive !== undefined ? isActive : true,
      createdBy: demoUserId // Demo mode - use a dummy ObjectId
    });

    res.status(201).json({
      success: true,
      message: 'Demo campus boundary created successfully',
      data: campus.getBoundaryInfo()
    });
  } catch (error) {
    console.error('Create demo campus boundary error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while creating demo campus boundary'
    });
  }
});

// @desc    Update campus boundary (Demo endpoint - no auth required)
// @route   PUT /api/campus/boundaries/demo/:id
// @access  Public (for demo purposes)
router.put('/boundaries/demo/:id', [
  param('id').isMongoId().withMessage('Invalid campus ID'),
  body('name').optional().trim().isLength({ min: 2, max: 100 }).withMessage('Name must be between 2 and 100 characters'),
  body('description').optional().trim().isLength({ max: 500 }).withMessage('Description cannot exceed 500 characters'),
  body('boundaryType').optional().isIn(['circle', 'polygon', 'rectangle']).withMessage('Invalid boundary type'),
  body('center.latitude').optional().isFloat({ min: -90, max: 90 }).withMessage('Invalid latitude'),
  body('center.longitude').optional().isFloat({ min: -180, max: 180 }).withMessage('Invalid longitude'),
  body('radius').optional().isFloat({ min: 1, max: 10000 }).withMessage('Radius must be between 1 and 10000 meters'),
  body('polygonPoints').optional().isArray().withMessage('Polygon points must be an array'),
  body('bounds.southwest.latitude').optional().isFloat({ min: -90, max: 90 }).withMessage('Invalid southwest latitude'),
  body('bounds.southwest.longitude').optional().isFloat({ min: -180, max: 180 }).withMessage('Invalid southwest longitude'),
  body('bounds.northeast.latitude').optional().isFloat({ min: -90, max: 90 }).withMessage('Invalid northeast latitude'),
  body('bounds.northeast.longitude').optional().isFloat({ min: -180, max: 180 }).withMessage('Invalid northeast longitude'),
  body('isActive').optional().isBoolean().withMessage('isActive must be a boolean')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const campus = await Campus.findById(req.params.id);
    if (!campus) {
      return res.status(404).json({
        success: false,
        message: 'Campus boundary not found'
      });
    }

    const updateData = { ...req.body };
    const updatedCampus = await Campus.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      message: 'Demo campus boundary updated successfully',
      data: updatedCampus.getBoundaryInfo()
    });
  } catch (error) {
    console.error('Update demo campus boundary error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while updating demo campus boundary'
    });
  }
});

// @desc    Delete campus boundary (Demo endpoint - no auth required)
// @route   DELETE /api/campus/boundaries/demo/:id
// @access  Public (for demo purposes)
router.delete('/boundaries/demo/:id', [
  param('id').isMongoId().withMessage('Invalid campus ID')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const campus = await Campus.findById(req.params.id);
    if (!campus) {
      return res.status(404).json({
        success: false,
        message: 'Campus boundary not found'
      });
    }

    await Campus.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Demo campus boundary deleted successfully'
    });
  } catch (error) {
    console.error('Delete demo campus boundary error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while deleting demo campus boundary'
    });
  }
});

// @desc    Create new campus boundary
// @route   POST /api/campus/boundaries
// @access  Private (Teacher/Admin only)
router.post('/boundaries', protect, authorize('teacher', 'admin'), [
  body('name').trim().isLength({ min: 2, max: 100 }).withMessage('Name must be between 2 and 100 characters'),
  body('description').optional().trim().isLength({ max: 500 }).withMessage('Description cannot exceed 500 characters'),
  body('boundaryType').isIn(['circle', 'polygon', 'rectangle']).withMessage('Invalid boundary type'),
  body('center.latitude').isFloat({ min: -90, max: 90 }).withMessage('Invalid latitude'),
  body('center.longitude').isFloat({ min: -180, max: 180 }).withMessage('Invalid longitude'),
  body('radius').optional().isFloat({ min: 1, max: 10000 }).withMessage('Radius must be between 1 and 10000 meters'),
  body('polygonPoints').optional().isArray().withMessage('Polygon points must be an array'),
  body('bounds.southwest.latitude').isFloat({ min: -90, max: 90 }).withMessage('Invalid southwest latitude'),
  body('bounds.southwest.longitude').isFloat({ min: -180, max: 180 }).withMessage('Invalid southwest longitude'),
  body('bounds.northeast.latitude').isFloat({ min: -90, max: 90 }).withMessage('Invalid northeast latitude'),
  body('bounds.northeast.longitude').isFloat({ min: -180, max: 180 }).withMessage('Invalid northeast longitude'),
  body('isActive').optional().isBoolean().withMessage('isActive must be a boolean')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { name, description, boundaryType, center, radius, polygonPoints, bounds, isActive } = req.body;

    // Check if campus with same name already exists
    const existingCampus = await Campus.findOne({ name });
    if (existingCampus) {
      return res.status(400).json({
        success: false,
        message: 'Campus boundary with this name already exists'
      });
    }

    // Validate boundary-specific requirements
    if (boundaryType === 'circle' && (!radius || radius <= 0)) {
      return res.status(400).json({
        success: false,
        message: 'Circle boundary requires a valid radius'
      });
    }

    if (boundaryType === 'polygon' && (!polygonPoints || polygonPoints.length < 3)) {
      return res.status(400).json({
        success: false,
        message: 'Polygon boundary requires at least 3 points'
      });
    }

    if (boundaryType === 'rectangle') {
      if (bounds.southwest.latitude >= bounds.northeast.latitude ||
          bounds.southwest.longitude >= bounds.northeast.longitude) {
        return res.status(400).json({
          success: false,
          message: 'Invalid rectangle bounds'
        });
      }
    }

    const campus = await Campus.create({
      name,
      description,
      boundaryType,
      center,
      radius: radius || 0,
      polygonPoints: polygonPoints || [],
      bounds,
      isActive: isActive !== undefined ? isActive : true,
      createdBy: req.user._id
    });

    await campus.populate('createdBy', 'name email role');

    res.status(201).json({
      success: true,
      message: 'Campus boundary created successfully',
      data: campus.getBoundaryInfo()
    });
  } catch (error) {
    console.error('Create campus boundary error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while creating campus boundary'
    });
  }
});

// @desc    Update campus boundary
// @route   PUT /api/campus/boundaries/:id
// @access  Private (Teacher/Admin only)
router.put('/boundaries/:id', protect, authorize('teacher', 'admin'), [
  param('id').isMongoId().withMessage('Invalid campus ID'),
  body('name').optional().trim().isLength({ min: 2, max: 100 }).withMessage('Name must be between 2 and 100 characters'),
  body('description').optional().trim().isLength({ max: 500 }).withMessage('Description cannot exceed 500 characters'),
  body('boundaryType').optional().isIn(['circle', 'polygon', 'rectangle']).withMessage('Invalid boundary type'),
  body('center.latitude').optional().isFloat({ min: -90, max: 90 }).withMessage('Invalid latitude'),
  body('center.longitude').optional().isFloat({ min: -180, max: 180 }).withMessage('Invalid longitude'),
  body('radius').optional().isFloat({ min: 1, max: 10000 }).withMessage('Radius must be between 1 and 10000 meters'),
  body('polygonPoints').optional().isArray().withMessage('Polygon points must be an array'),
  body('bounds.southwest.latitude').optional().isFloat({ min: -90, max: 90 }).withMessage('Invalid southwest latitude'),
  body('bounds.southwest.longitude').optional().isFloat({ min: -180, max: 180 }).withMessage('Invalid southwest longitude'),
  body('bounds.northeast.latitude').optional().isFloat({ min: -90, max: 90 }).withMessage('Invalid northeast latitude'),
  body('bounds.northeast.longitude').optional().isFloat({ min: -180, max: 180 }).withMessage('Invalid northeast longitude'),
  body('isActive').optional().isBoolean().withMessage('isActive must be a boolean')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const campus = await Campus.findById(req.params.id);
    if (!campus) {
      return res.status(404).json({
        success: false,
        message: 'Campus boundary not found'
      });
    }

    // Check if user has permission to update this campus
    if (campus.createdBy.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this campus boundary'
      });
    }

    const updateData = { ...req.body };
    
    // Check if name is being changed and if it conflicts
    if (updateData.name && updateData.name !== campus.name) {
      const existingCampus = await Campus.findOne({ 
        name: updateData.name, 
        _id: { $ne: campus._id } 
      });
      if (existingCampus) {
        return res.status(400).json({
          success: false,
          message: 'Campus boundary with this name already exists'
        });
      }
    }

    const updatedCampus = await Campus.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    ).populate('createdBy', 'name email role');

    res.json({
      success: true,
      message: 'Campus boundary updated successfully',
      data: updatedCampus.getBoundaryInfo()
    });
  } catch (error) {
    console.error('Update campus boundary error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while updating campus boundary'
    });
  }
});

// @desc    Delete campus boundary
// @route   DELETE /api/campus/boundaries/:id
// @access  Private (Admin only)
router.delete('/boundaries/:id', protect, authorize('admin'), [
  param('id').isMongoId().withMessage('Invalid campus ID')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const campus = await Campus.findById(req.params.id);
    if (!campus) {
      return res.status(404).json({
        success: false,
        message: 'Campus boundary not found'
      });
    }

    await Campus.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Campus boundary deleted successfully'
    });
  } catch (error) {
    console.error('Delete campus boundary error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while deleting campus boundary'
    });
  }
});

// @desc    Validate location against campus boundaries
// @route   POST /api/campus/validate-location
// @access  Private
router.post('/validate-location', protect, [
  body('latitude').isFloat({ min: -90, max: 90 }).withMessage('Invalid latitude'),
  body('longitude').isFloat({ min: -180, max: 180 }).withMessage('Invalid longitude')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { latitude, longitude } = req.body;

    // Get all active campus boundaries
    const activeCampuses = await Campus.find({ isActive: true });

    if (activeCampuses.length === 0) {
      return res.json({
        success: true,
        data: {
          isInsideCampus: false,
          message: 'No active campus boundaries configured',
          campuses: []
        }
      });
    }

    const results = [];
    let isInsideAnyCampus = false;

    for (const campus of activeCampuses) {
      const isInside = campus.isPointInside(latitude, longitude);
      const distanceToCenter = campus.distanceToCenter(latitude, longitude);

      results.push({
        campusId: campus._id,
        campusName: campus.name,
        isInside,
        distanceToCenter: Math.round(distanceToCenter),
        boundaryType: campus.boundaryType
      });

      if (isInside) {
        isInsideAnyCampus = true;
      }
    }

    res.json({
      success: true,
      data: {
        isInsideCampus: isInsideAnyCampus,
        message: isInsideAnyCampus 
          ? 'Location is within campus boundaries' 
          : 'Location is outside all campus boundaries',
        campuses: results,
        userLocation: {
          latitude,
          longitude
        }
      }
    });
  } catch (error) {
    console.error('Validate location error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while validating location'
    });
  }
});

// @desc    Get campus statistics
// @route   GET /api/campus/statistics
// @access  Private (Admin only)
router.get('/statistics', protect, authorize('admin'), async (req, res) => {
  try {
    const totalCampuses = await Campus.countDocuments();
    const activeCampuses = await Campus.countDocuments({ isActive: true });
    const inactiveCampuses = totalCampuses - activeCampuses;

    const boundaryTypeStats = await Campus.aggregate([
      {
        $group: {
          _id: '$boundaryType',
          count: { $sum: 1 }
        }
      }
    ]);

    const recentCampuses = await Campus.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .populate('createdBy', 'name email')
      .select('name boundaryType isActive createdAt createdBy');

    res.json({
      success: true,
      data: {
        total: totalCampuses,
        active: activeCampuses,
        inactive: inactiveCampuses,
        boundaryTypes: boundaryTypeStats,
        recent: recentCampuses
      }
    });
  } catch (error) {
    console.error('Get campus statistics error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching campus statistics'
    });
  }
});

module.exports = router;
