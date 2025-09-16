const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { protect, authorize } = require('../middleware/auth');
const Attendance = require('../models/Attendance');
const Session = require('../models/Session');
const Class = require('../models/Class');

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


