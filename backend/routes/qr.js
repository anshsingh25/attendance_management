const express = require('express');
const QRCode = require('qrcode');
const { body, validationResult } = require('express-validator');
const Class = require('../models/Class');
const Session = require('../models/Session');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

// @desc    Generate QR code for class session
// @route   POST /api/qr/generate
// @access  Private (Teacher only)
router.post('/generate', protect, authorize('teacher'), [
  body('classId').isMongoId().withMessage('Valid class ID is required'),
  body('duration').isInt({ min: 5, max: 120 }).withMessage('Duration must be between 5 and 120 minutes')
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

    const { classId, duration = 60 } = req.body;

    // Find the class
    const classData = await Class.findById(classId);
    if (!classData) {
      return res.status(404).json({
        success: false,
        message: 'Class not found'
      });
    }

    // Check if teacher owns this class
    if (classData.teacher.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to generate QR for this class'
      });
    }

    // Create session data
    const sessionData = {
      classId: classData._id,
      code: classData.code,
      subject: classData.subject,
      teacher: req.user._id,
      timestamp: Date.now(),
      expiresAt: Date.now() + (duration * 60 * 1000) // Convert minutes to milliseconds
    };

    // Generate QR code data
    const qrData = JSON.stringify(sessionData);

    // Create QR code image
    const qrCodeImage = await QRCode.toDataURL(qrData, {
      width: 300,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });

    // Create session record
    const session = await Session.create({
      class: classId,
      teacher: req.user._id,
      date: new Date(),
      startTime: new Date(),
      endTime: new Date(Date.now() + (duration * 60 * 1000)),
      qrCode: {
        data: qrData,
        expiresAt: new Date(Date.now() + (duration * 60 * 1000)),
        isActive: true
      },
      status: 'active',
      allowWifiAutoMark: Boolean(req.body.allowWifiAutoMark),
      attendanceWindow: {
        start: new Date(),
        end: new Date(Date.now() + (duration * 60 * 1000))
      },
      totalStudents: classData.students.length
    });

    res.json({
      success: true,
      message: 'QR code generated successfully',
      data: {
        sessionId: session._id,
        qrCode: qrCodeImage,
        expiresAt: session.qrCode.expiresAt,
        duration: duration,
        classInfo: {
          name: classData.name,
          code: classData.code,
          subject: classData.subject
        }
      }
    });
  } catch (error) {
    console.error('QR generation error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during QR generation'
    });
  }
});

// @desc    Validate QR code
// @route   POST /api/qr/validate
// @access  Private (Student only)
router.post('/validate', protect, authorize('student'), [
  body('qrData').notEmpty().withMessage('QR data is required'),
  body('location').isObject().withMessage('Location data is required'),
  body('wifiSSID').notEmpty().withMessage('WiFi SSID is required')
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

    const { qrData, location, wifiSSID, deviceInfo } = req.body;

    // Parse QR data
    let sessionData;
    try {
      sessionData = JSON.parse(qrData);
    } catch (error) {
      return res.status(400).json({
        success: false,
        message: 'Invalid QR code format'
      });
    }

    // Find the session
    const session = await Session.findById(sessionData.sessionId || sessionData.classId)
      .populate('class')
      .populate('teacher', 'name email');

    if (!session) {
      return res.status(404).json({
        success: false,
        message: 'Session not found'
      });
    }

    // Check if QR code is expired
    if (new Date() > session.qrCode.expiresAt) {
      return res.status(400).json({
        success: false,
        message: 'QR code has expired'
      });
    }

    // Check if session is active
    if (session.status !== 'active') {
      return res.status(400).json({
        success: false,
        message: 'Session is not active'
      });
    }

    // Check if student is enrolled in the class
    const isEnrolled = session.class.students.includes(req.user._id);
    if (!isEnrolled) {
      return res.status(403).json({
        success: false,
        message: 'You are not enrolled in this class'
      });
    }

    // Validate WiFi SSID
    if (session.class.wifiSSID !== wifiSSID) {
      return res.status(400).json({
        success: false,
        message: 'You must be connected to the classroom WiFi'
      });
    }

    // Validate location (optional - can be implemented based on requirements)
    const distance = calculateDistance(
      location.latitude,
      location.longitude,
      session.class.location.latitude,
      session.class.location.longitude
    );

    if (distance > session.class.location.radius) {
      return res.status(400).json({
        success: false,
        message: 'You must be within the classroom area'
      });
    }

    // Check if attendance already marked
    const Attendance = require('../models/Attendance');
    const existingAttendance = await Attendance.findOne({
      student: req.user._id,
      session: session._id
    });

    if (existingAttendance) {
      return res.status(400).json({
        success: false,
        message: 'Attendance already marked for this session'
      });
    }

    // Determine if student is late
    const now = new Date();
    const sessionStart = new Date(session.startTime);
    const lateThreshold = 15; // 15 minutes
    const isLate = (now - sessionStart) > (lateThreshold * 60 * 1000);

    // Mark attendance
    const attendance = await Attendance.create({
      student: req.user._id,
      class: session.class._id,
      session: session._id,
      status: isLate ? 'late' : 'present',
      location: {
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy
      },
      wifiSSID: wifiSSID,
      deviceInfo: deviceInfo,
      verificationMethod: 'qr_code',
      isVerified: true
    });

    // Update session counts
    if (isLate) {
      session.lateCount += 1;
    } else {
      session.presentCount += 1;
    }
    await session.save();

    res.json({
      success: true,
      message: `Attendance marked successfully - ${isLate ? 'Late' : 'Present'}`,
      data: {
        attendance,
        session: {
          id: session._id,
          class: session.class.name,
          subject: session.class.subject,
          teacher: session.teacher.name,
          status: isLate ? 'late' : 'present',
          markedAt: attendance.markedAt
        }
      }
    });
  } catch (error) {
    console.error('QR validation error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during QR validation'
    });
  }
});

// @desc    Get active sessions for teacher
// @route   GET /api/qr/active-sessions
// @access  Private (Teacher only)
router.get('/active-sessions', protect, authorize('teacher'), async (req, res) => {
  try {
    const sessions = await Session.find({
      teacher: req.user._id,
      status: 'active',
      'qrCode.expiresAt': { $gt: new Date() }
    })
    .populate('class', 'name code subject')
    .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: sessions
    });
  } catch (error) {
    console.error('Get active sessions error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    End session
// @route   PUT /api/qr/end-session/:sessionId
// @access  Private (Teacher only)
router.put('/end-session/:sessionId', protect, authorize('teacher'), async (req, res) => {
  try {
    const session = await Session.findById(req.params.sessionId);

    if (!session) {
      return res.status(404).json({
        success: false,
        message: 'Session not found'
      });
    }

    if (session.teacher.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to end this session'
      });
    }

    session.status = 'completed';
    session.endTime = new Date();
    session.qrCode.isActive = false;
    await session.save();

    res.json({
      success: true,
      message: 'Session ended successfully',
      data: session
    });
  } catch (error) {
    console.error('End session error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Helper function to calculate distance between two coordinates
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

module.exports = router;

// @desc    Toggle WiFi auto-mark for a session
// @route   PUT /api/qr/session/:sessionId/wifi-auto
// @access  Private (Teacher only)
router.put('/session/:sessionId/wifi-auto', protect, authorize('teacher'), [
  require('express-validator').param('sessionId').isMongoId(),
  require('express-validator').body('allow').isBoolean()
], async (req, res) => {
  try {
    const errors = require('express-validator').validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, message: 'Validation failed', errors: errors.array() });
    }

    const session = await Session.findById(req.params.sessionId);
    if (!session) {
      return res.status(404).json({ success: false, message: 'Session not found' });
    }
    if (session.teacher.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    session.allowWifiAutoMark = req.body.allow;
    await session.save();

    res.json({ success: true, message: 'WiFi auto-mark updated', data: { allowWifiAutoMark: session.allowWifiAutoMark } });
  } catch (error) {
    console.error('Toggle wifi auto-mark error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @desc    Auto-mark attendance by WiFi (no QR)
// @route   POST /api/qr/auto-mark
// @access  Private (Student only)
router.post('/auto-mark', protect, authorize('student'), [
  require('express-validator').body('classId').isMongoId(),
  require('express-validator').body('wifiSSID').notEmpty(),
  require('express-validator').body('location').optional().isObject()
], async (req, res) => {
  try {
    const { classId, wifiSSID, location, deviceInfo } = req.body;

    const classData = await Class.findById(classId);
    if (!classData) {
      return res.status(404).json({ success: false, message: 'Class not found' });
    }

    // Must match classroom WiFi
    if (classData.wifiSSID !== wifiSSID) {
      return res.status(400).json({ success: false, message: 'You must be connected to the classroom WiFi' });
    }

    // Find active session that allows auto-mark
    const session = await Session.findOne({
      class: classId,
      status: 'active',
      'qrCode.expiresAt': { $gt: new Date() },
      allowWifiAutoMark: true
    });

    if (!session) {
      return res.status(400).json({ success: false, message: 'No active session allowing WiFi auto-mark' });
    }

    // Verify enrollment
    const isEnrolled = classData.students.includes(req.user._id);
    if (!isEnrolled) {
      return res.status(403).json({ success: false, message: 'You are not enrolled in this class' });
    }

    // Optional geofence validation
    if (location && classData.location?.latitude && classData.location?.longitude) {
      const distance = calculateDistance(
        location.latitude,
        location.longitude,
        classData.location.latitude,
        classData.location.longitude
      );
      if (distance > (classData.location.radius || 50)) {
        return res.status(400).json({ success: false, message: 'You must be within the classroom area' });
      }
    }

    const Attendance = require('../models/Attendance');
    const existingAttendance = await Attendance.findOne({ student: req.user._id, session: session._id });
    if (existingAttendance) {
      return res.status(200).json({ success: true, message: 'Attendance already marked', data: existingAttendance });
    }

    // Determine late
    const now = new Date();
    const isLate = (now - new Date(session.startTime)) > (15 * 60 * 1000);

    const attendance = await Attendance.create({
      student: req.user._id,
      class: classId,
      session: session._id,
      status: isLate ? 'late' : 'present',
      wifiSSID,
      deviceInfo,
      verificationMethod: 'manual',
      isVerified: true,
      location: location ? { latitude: location.latitude, longitude: location.longitude, accuracy: location.accuracy } : undefined
    });

    if (isLate) session.lateCount += 1; else session.presentCount += 1;
    await session.save();

    res.json({ success: true, message: 'Attendance marked automatically via WiFi', data: attendance });
  } catch (error) {
    console.error('Auto-mark error:', error);
    res.status(500).json({ success: false, message: 'Server error during auto-mark' });
  }
});
