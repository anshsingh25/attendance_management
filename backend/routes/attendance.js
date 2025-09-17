const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { protect, authorize } = require('../middleware/auth');
const Attendance = require('../models/Attendance');
const Session = require('../models/Session');
const Class = require('../models/Class');
const QRCode = require('../models/QRCode');

const router = express.Router();

function handleValidation(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, message: 'Validation failed', errors: errors.array() });
  }
}

// @desc    List attendance (teacher/admin) with filters
// @route   GET /api/attendance
// @access  Private (teacher/admin)
router.get('/', protect, authorize('teacher', 'admin'), [
  query('classId').optional().isMongoId(),
  query('sessionId').optional().isMongoId(),
  query('studentId').optional().isMongoId(),
  query('status').optional().isIn(['present', 'late', 'absent', 'excused']),
  query('from').optional().isISO8601(),
  query('to').optional().isISO8601(),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('page').optional().isInt({ min: 1 })
], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const { classId, sessionId, studentId, status, from, to } = req.query;
  const limit = parseInt(req.query.limit || '20', 10);
  const page = parseInt(req.query.page || '1', 10);

  const filter = {};
  if (classId) filter.class = classId;
  if (sessionId) filter.session = sessionId;
  if (studentId) filter.student = studentId;
  if (status) filter.status = status;
  if (from || to) filter.markedAt = {};
  if (from) filter.markedAt.$gte = new Date(from);
  if (to) filter.markedAt.$lte = new Date(to);

  // Teacher can only view their classes
  if (req.user.role === 'teacher') {
    const classes = await Class.find({ teacher: req.user._id }).select('_id');
    const allowed = classes.map(c => c._id);
    filter.class = filter.class ? filter.class : { $in: allowed };
  }

  const [items, total] = await Promise.all([
    Attendance.find(filter)
      .populate('student', 'name email studentId')
      .populate('class', 'name code subject')
      .populate('session', 'date startTime endTime status')
      .sort({ markedAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit),
    Attendance.countDocuments(filter)
  ]);

  res.json({ success: true, data: items, meta: { total, page, limit } });
});

// @desc    Student active sessions
// @route   GET /api/attendance/sessions/active
// @access  Private (student)
router.get('/sessions/active', protect, authorize('student'), async (req, res) => {
  try {
    const active = await Session.find({
      status: 'active',
      'qrCode.expiresAt': { $gt: new Date() }
    }).populate('class', 'name code subject students wifiSSID');

    const enrolled = active.filter(s => s.class.students.some(id => id.toString() === req.user._id.toString()));
    res.json({ success: true, data: enrolled });
  } catch (e) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @desc    Manual mark attendance (teacher/admin)
// @route   POST /api/attendance/manual
// @access  Private (teacher/admin)
router.post('/manual', protect, authorize('teacher', 'admin'), [
  body('studentId').isMongoId(),
  body('classId').isMongoId(),
  body('sessionId').isMongoId(),
  body('status').isIn(['present', 'late', 'absent', 'excused'])
], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const { studentId, classId, sessionId, status, notes } = req.body;

  const session = await Session.findById(sessionId).populate('class');
  if (!session) return res.status(404).json({ success: false, message: 'Session not found' });
  if (req.user.role === 'teacher' && session.teacher.toString() !== req.user._id.toString()) {
    return res.status(403).json({ success: false, message: 'Not authorized' });
  }

  try {
    const attendance = await Attendance.findOneAndUpdate(
      { student: studentId, session: sessionId },
      {
        student: studentId,
        class: classId,
        session: sessionId,
        status,
        markedBy: 'teacher',
        notes,
        isVerified: true,
        verificationMethod: 'manual'
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    res.status(201).json({ success: true, message: 'Attendance recorded', data: attendance });
  } catch (e) {
    res.status(400).json({ success: false, message: 'Could not record attendance', error: e.message });
  }
});

// @desc    Attendance summary for a class
// @route   GET /api/attendance/summary/class/:classId
// @access  Private (teacher/admin)
router.get('/summary/class/:classId', protect, authorize('teacher', 'admin'), [param('classId').isMongoId()], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const classId = req.params.classId;
  const mongoose = require('mongoose');
  const agg = await Attendance.aggregate([
    { $match: { class: new mongoose.Types.ObjectId(classId) } },
    { $group: { _id: '$status', count: { $sum: 1 } } }
  ]);
  const summary = ['present', 'late', 'absent', 'excused'].reduce((acc, k) => {
    acc[k] = agg.find(a => a._id === k)?.count || 0;
    return acc;
  }, {});
  res.json({ success: true, data: summary });
});

// @desc    My attendance (student)
// @route   GET /api/attendance/me
// @access  Private (student)
router.get('/me', protect, authorize('student'), [
  query('classId').optional().isMongoId(),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('page').optional().isInt({ min: 1 })
], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const { classId } = req.query;
  const limit = parseInt(req.query.limit || '20', 10);
  const page = parseInt(req.query.page || '1', 10);
  const filter = { student: req.user._id };
  if (classId) filter.class = classId;
  const [items, total] = await Promise.all([
    Attendance.find(filter)
      .populate('class', 'name code subject')
      .populate('session', 'date startTime endTime status')
      .sort({ markedAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit),
    Attendance.countDocuments(filter)
  ]);
  res.json({ success: true, data: items, meta: { total, page, limit } });
});

// Demo endpoints for testing without authentication

// @desc    Generate demo attendance code
// @route   POST /api/attendance/generate-code/demo
// @access  Public (demo)
router.post('/generate-code/demo', [
  body('duration').isInt({ min: 1, max: 120 }).withMessage('Duration must be between 1 and 120 minutes'),
  body('classId').optional().isString(),
  body('subject').optional().isString()
], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  
  try {
    const { duration = 60, classId = 'demo_class', subject = 'Demo Class' } = req.body;
    
    // Generate 6-digit alphanumeric code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    
    // Calculate expiration time (this is just a placeholder, actual expiration starts when countdown begins)
    const expiresAt = new Date(Date.now() + duration * 60 * 1000);
    
    // Create QR code in database
    const qrCode = new QRCode({
      code,
      duration,
      expiresAt,
      classId,
      subject,
      isActive: true,
      countdownStarted: false,
      actualExpiresAt: null,
      createdBy: 'demo_teacher'
    });
    
    await qrCode.save();
    
    res.status(201).json({
      success: true,
      message: 'Attendance code generated successfully',
      data: {
        code: qrCode.code,
        duration: qrCode.duration,
        expiresAt: qrCode.expiresAt,
        classId: qrCode.classId,
        subject: qrCode.subject,
        isActive: qrCode.isActive,
        createdAt: qrCode.createdAt,
        createdBy: qrCode.createdBy
      }
    });
  } catch (error) {
    console.error('Error generating demo attendance code:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during code generation'
    });
  }
});

// @desc    Start countdown for QR code
// @route   POST /api/attendance/start-countdown/demo
// @access  Public (demo)
router.post('/start-countdown/demo', [
  body('code').isLength({ min: 6, max: 6 }).withMessage('Code must be 6 characters')
], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  
  try {
    const { code } = req.body;
    
    const qrCode = await QRCode.findActiveByCode(code);
    if (!qrCode) {
      return res.status(404).json({
        success: false,
        message: 'QR code not found'
      });
    }
    
    if (qrCode.countdownStarted) {
      return res.status(400).json({
        success: false,
        message: 'Countdown already started for this QR code'
      });
    }
    
    // Start countdown using the model method
    await qrCode.startCountdown();
    
    res.status(200).json({
      success: true,
      message: 'Countdown started successfully',
      data: {
        code: qrCode.code,
        expiresAt: qrCode.actualExpiresAt,
        duration: qrCode.duration
      }
    });
  } catch (error) {
    console.error('Error starting countdown:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during countdown start'
    });
  }
});

// @desc    Validate demo attendance code
// @route   POST /api/attendance/validate-code/demo
// @access  Public (demo)
router.post('/validate-code/demo', [
  body('code').isLength({ min: 6, max: 6 }).withMessage('Code must be 6 characters'),
  body('studentId').isString().withMessage('Student ID is required'),
  body('location').optional().isObject(),
  body('timestamp').optional().isISO8601()
], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  
  try {
    const { code, studentId, location, timestamp } = req.body;
    
    // Check if QR code exists in database
    const qrCode = await QRCode.findActiveByCode(code);
    if (!qrCode) {
      return res.status(404).json({
        success: false,
        message: 'QR code not found or invalid'
      });
    }
    
    // Check if countdown has started
    if (!qrCode.countdownStarted) {
      return res.status(400).json({
        success: false,
        message: 'QR code countdown has not started yet. Please wait for teacher to start the countdown.'
      });
    }
    
    // Check if QR code has expired
    if (qrCode.isExpired()) {
      // Deactivate expired code
      await qrCode.deactivate();
      return res.status(400).json({
        success: false,
        message: 'QR code has expired. Please ask teacher to generate a new one.'
      });
    }
    
    // Check if QR code is still active
    if (!qrCode.isActive) {
      return res.status(400).json({
        success: false,
        message: 'QR code is no longer active'
      });
    }
    
    // Successful validation
    const attendanceRecord = {
      id: new Date().getTime().toString(),
      code,
      studentId,
      location,
      timestamp: timestamp || new Date().toISOString(),
      status: 'present',
      validatedAt: new Date(),
      classId: qrCode.classId,
      subject: qrCode.subject,
      expiresAt: qrCode.actualExpiresAt
    };
    
    res.status(200).json({
      success: true,
      message: 'Attendance marked successfully',
      data: attendanceRecord
    });
  } catch (error) {
    console.error('Error validating demo attendance code:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during code validation'
    });
  }
});

// @desc    Get active attendance codes (demo)
// @route   GET /api/attendance/codes/active
// @access  Public (demo)
router.get('/codes/active', async (req, res) => {
  try {
    // Query database for active codes
    const activeCodes = await QRCode.find({
      isActive: true,
      countdownStarted: true,
      actualExpiresAt: { $gt: new Date() }
    }).sort({ createdAt: -1 });
    
    res.status(200).json({
      success: true,
      data: activeCodes,
      message: activeCodes.length > 0 ? 'Active codes found' : 'No active codes found'
    });
  } catch (error) {
    console.error('Error getting active codes:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;

// --- Analytics Endpoints ---
// @desc    Attendance summary for a student across classes
// @route   GET /api/attendance/summary/student/:studentId
// @access  Private (teacher/admin)
router.get('/summary/student/:studentId', protect, authorize('teacher', 'admin'), [param('studentId').isMongoId()], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const mongoose = require('mongoose');
  const studentId = req.params.studentId;

  // If teacher, restrict to their classes
  let classFilter = {};
  if (req.user.role === 'teacher') {
    const classes = await Class.find({ teacher: req.user._id }).select('_id');
    classFilter = { class: { $in: classes.map(c => c._id) } };
  }

  const agg = await Attendance.aggregate([
    { $match: { student: new mongoose.Types.ObjectId(studentId), ...classFilter } },
    { $group: { _id: '$status', count: { $sum: 1 } } }
  ]);

  const summary = ['present', 'late', 'absent', 'excused'].reduce((acc, k) => {
    acc[k] = agg.find(a => a._id === k)?.count || 0;
    return acc;
  }, {});

  res.json({ success: true, data: summary });
});

// @desc    Attendance summary for a session
// @route   GET /api/attendance/summary/session/:sessionId
// @access  Private (teacher/admin)
router.get('/summary/session/:sessionId', protect, authorize('teacher', 'admin'), [param('sessionId').isMongoId()], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const mongoose = require('mongoose');
  const sessionId = req.params.sessionId;

  const session = await Session.findById(sessionId).populate('class', 'name code subject teacher');
  if (!session) return res.status(404).json({ success: false, message: 'Session not found' });
  if (req.user.role === 'teacher' && session.teacher.toString() !== req.user._id.toString()) {
    return res.status(403).json({ success: false, message: 'Not authorized' });
  }

  const agg = await Attendance.aggregate([
    { $match: { session: new mongoose.Types.ObjectId(sessionId) } },
    { $group: { _id: '$status', count: { $sum: 1 } } }
  ]);
  const summary = ['present', 'late', 'absent', 'excused'].reduce((acc, k) => {
    acc[k] = agg.find(a => a._id === k)?.count || 0;
    return acc;
  }, {});

  res.json({ success: true, data: { session, summary } });
});

// @desc    Attendance trend over time for a class
// @route   GET /api/attendance/summary/class/:classId/trend
// @access  Private (teacher/admin)
router.get('/summary/class/:classId/trend', protect, authorize('teacher', 'admin'), [param('classId').isMongoId(), query('from').optional().isISO8601(), query('to').optional().isISO8601()], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const mongoose = require('mongoose');
  const { classId } = req.params;
  const { from, to } = req.query;
  const match = { class: new mongoose.Types.ObjectId(classId) };
  if (from || to) match.markedAt = {};
  if (from) match.markedAt.$gte = new Date(from);
  if (to) match.markedAt.$lte = new Date(to);

  const agg = await Attendance.aggregate([
    { $match: match },
    { $group: { _id: { y: { $year: '$markedAt' }, m: { $month: '$markedAt' }, d: { $dayOfMonth: '$markedAt' } }, present: { $sum: { $cond: [{ $eq: ['$status', 'present'] }, 1, 0] } }, late: { $sum: { $cond: [{ $eq: ['$status', 'late'] }, 1, 0] } }, absent: { $sum: { $cond: [{ $eq: ['$status', 'absent'] }, 1, 0] } }, excused: { $sum: { $cond: [{ $eq: ['$status', 'excused'] }, 1, 0] } } } },
    { $sort: { '_id.y': 1, '_id.m': 1, '_id.d': 1 } }
  ]);

  res.json({ success: true, data: agg.map(row => ({ date: new Date(row._id.y, row._id.m - 1, row._id.d), present: row.present, late: row.late, absent: row.absent, excused: row.excused })) });
});


