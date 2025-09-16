const express = require('express');
const router = express.Router();
const CampusBoundary = require('../models/CampusBoundary');

// Demo endpoints (no authentication required)
// GET /api/campus/boundaries/all - Get all campus boundaries
router.get('/boundaries/all', async (req, res) => {
  try {
    const boundaries = await CampusBoundary.find({});
    res.json({
      success: true,
      data: boundaries,
      message: 'Campus boundaries retrieved successfully'
    });
  } catch (error) {
    console.error('Error getting all campus boundaries:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve campus boundaries',
      error: error.message
    });
  }
});

// POST /api/campus/boundaries/demo - Create campus boundary (demo)
router.post('/boundaries/demo', async (req, res) => {
  try {
    const {
      name,
      description,
      boundaryType,
      center,
      radius,
      polygonPoints,
      bounds,
      isActive,
      createdBy
    } = req.body;

    // Check if teacher already has an active campus boundary
    const existingActiveCampus = await CampusBoundary.findOne({
      createdBy: createdBy || 'demo_user',
      isActive: true
    });

    if (existingActiveCampus) {
      return res.status(400).json({
        success: false,
        message: `Teacher already has an active campus boundary: "${existingActiveCampus.name}". Please deactivate the existing campus before creating a new one.`,
        existingCampus: {
          id: existingActiveCampus._id,
          name: existingActiveCampus.name,
          description: existingActiveCampus.description
        }
      });
    }

    // Create new campus boundary
    const campusBoundary = new CampusBoundary({
      name,
      description,
      boundaryType,
      center: {
        latitude: center.latitude,
        longitude: center.longitude
      },
      radius: radius || 0,
      polygonPoints: polygonPoints || [],
      bounds: bounds ? {
        southwest: {
          latitude: bounds.southwest.latitude,
          longitude: bounds.southwest.longitude
        },
        northeast: {
          latitude: bounds.northeast.latitude,
          longitude: bounds.northeast.longitude
        }
      } : null,
      isActive: isActive !== undefined ? isActive : true,
      createdBy: createdBy || 'demo_user'
    });

    const savedBoundary = await campusBoundary.save();
    
    res.status(201).json({
      success: true,
      data: savedBoundary,
      message: 'Campus boundary created successfully'
    });
  } catch (error) {
    console.error('Error creating campus boundary:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create campus boundary',
      error: error.message
    });
  }
});

// PUT /api/campus/boundaries/demo/:id - Update campus boundary (demo)
router.put('/boundaries/demo/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const updatedBoundary = await CampusBoundary.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!updatedBoundary) {
      return res.status(404).json({
        success: false,
        message: 'Campus boundary not found'
      });
    }

    res.json({
      success: true,
      data: updatedBoundary,
      message: 'Campus boundary updated successfully'
    });
  } catch (error) {
    console.error('Error updating campus boundary:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update campus boundary',
      error: error.message
    });
  }
});

// DELETE /api/campus/boundaries/demo/:id - Delete campus boundary (demo)
router.delete('/boundaries/demo/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const deletedBoundary = await CampusBoundary.findByIdAndDelete(id);

    if (!deletedBoundary) {
      return res.status(404).json({
        success: false,
        message: 'Campus boundary not found'
      });
    }

    res.json({
      success: true,
      message: 'Campus boundary deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting campus boundary:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete campus boundary',
      error: error.message
    });
  }
});

// GET /api/campus/boundaries/realtime - Real-time sync endpoint
router.get('/boundaries/realtime', async (req, res) => {
  try {
    const boundaries = await CampusBoundary.find({ isActive: true });
    res.json({
      success: true,
      data: boundaries,
      message: 'Active campus boundaries retrieved successfully'
    });
  } catch (error) {
    console.error('Error getting realtime campus boundaries:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve realtime campus boundaries',
      error: error.message
    });
  }
});

module.exports = router;
