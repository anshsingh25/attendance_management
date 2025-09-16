const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { protect, authorize } = require('../middleware/auth');
const Class = require('../models/Class');
const User = require('../models/User');

const router = express.Router();

function handleValidation(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, message: 'Validation failed', errors: errors.array() });
  }
}

// @desc    Create class (teacher/admin)
// @route   POST /api/classes
// @access  Private (teacher/admin)
router.post('/', protect, authorize('teacher', 'admin'), [
  body('name').isLength({ min: 2, max: 100 }),
  body('code').isLength({ min: 2, max: 20 }).toUpperCase(),
  body('subject').notEmpty(),
  body('description').optional().isLength({ max: 500 }),
  body('schedule.days').isArray({ min: 1 }),
  body('schedule.startTime').notEmpty(),
  body('schedule.endTime').notEmpty(),
  body('schedule.room').notEmpty(),
  body('wifiSSID').notEmpty(),
  body('location.latitude').isFloat(),
  body('location.longitude').isFloat(),
  body('location.radius').optional().isInt({ min: 10, max: 500 }),
  body('semester').notEmpty(),
  body('academicYear').notEmpty()
], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const payload = { ...req.body, teacher: req.user._id };
  const cls = await Class.create(payload);
  await User.findByIdAndUpdate(req.user._id, { $addToSet: { teachingClasses: cls._id } });
  res.status(201).json({ success: true, message: 'Class created', data: cls });
});

// @desc    List classes (role-aware)
// @route   GET /api/classes
// @access  Private
router.get('/', protect, [
  query('q').optional().isString(),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('page').optional().isInt({ min: 1 })
], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const { q } = req.query;
  const limit = parseInt(req.query.limit || '20', 10);
  const page = parseInt(req.query.page || '1', 10);

  const filter = { isActive: true };
  if (q) filter.$or = [
    { name: new RegExp(q, 'i') },
    { code: new RegExp(q, 'i') },
    { subject: new RegExp(q, 'i') }
  ];

  if (req.user.role === 'teacher') filter.teacher = req.user._id;
  if (req.user.role === 'student') filter._id = { $in: req.user.enrolledClasses };

  const [items, total] = await Promise.all([
    Class.find(filter).populate('teacher', 'name email').sort({ createdAt: -1 }).skip((page - 1) * limit).limit(limit),
    Class.countDocuments(filter)
  ]);

  res.json({ success: true, data: items, meta: { total, page, limit } });
});

// @desc    Get class by id
// @route   GET /api/classes/:id
// @access  Private
router.get('/:id', protect, [param('id').isMongoId()], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const cls = await Class.findById(req.params.id)
    .populate('teacher', 'name email')
    .populate('students', 'name email studentId');
  if (!cls) return res.status(404).json({ success: false, message: 'Class not found' });
  res.json({ success: true, data: cls });
});

// @desc    Enroll students (teacher/admin)
// @route   POST /api/classes/:id/enroll
// @access  Private (teacher/admin)
router.post('/:id/enroll', protect, authorize('teacher', 'admin'), [
  param('id').isMongoId(),
  body('studentIds').isArray({ min: 1 }),
  body('studentIds.*').isMongoId()
], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const cls = await Class.findById(req.params.id);
  if (!cls) return res.status(404).json({ success: false, message: 'Class not found' });
  if (req.user.role === 'teacher' && cls.teacher.toString() !== req.user._id.toString()) {
    return res.status(403).json({ success: false, message: 'Not authorized' });
  }

  await Class.findByIdAndUpdate(cls._id, { $addToSet: { students: { $each: req.body.studentIds } } });
  await User.updateMany({ _id: { $in: req.body.studentIds } }, { $addToSet: { enrolledClasses: cls._id } });
  const updated = await Class.findById(cls._id).populate('students', 'name email studentId');
  res.json({ success: true, message: 'Students enrolled', data: updated });
});

// @desc    Remove student (teacher/admin)
// @route   DELETE /api/classes/:id/students/:studentId
// @access  Private (teacher/admin)
router.delete('/:id/students/:studentId', protect, authorize('teacher', 'admin'), [
  param('id').isMongoId(),
  param('studentId').isMongoId()
], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const cls = await Class.findById(req.params.id);
  if (!cls) return res.status(404).json({ success: false, message: 'Class not found' });
  if (req.user.role === 'teacher' && cls.teacher.toString() !== req.user._id.toString()) {
    return res.status(403).json({ success: false, message: 'Not authorized' });
  }
  await Class.findByIdAndUpdate(cls._id, { $pull: { students: req.params.studentId } });
  await User.findByIdAndUpdate(req.params.studentId, { $pull: { enrolledClasses: cls._id } });
  res.json({ success: true, message: 'Student removed' });
});

// @desc    Update class (teacher/admin)
// @route   PUT /api/classes/:id
// @access  Private (teacher/admin)
router.put('/:id', protect, authorize('teacher', 'admin'), [
  param('id').isMongoId(),
  body('name').optional().isLength({ min: 2, max: 100 }),
  body('code').optional().isLength({ min: 2, max: 20 }).toUpperCase(),
  body('subject').optional().notEmpty(),
  body('description').optional().isLength({ max: 500 }),
  body('schedule.days').optional().isArray({ min: 1 }),
  body('schedule.startTime').optional().notEmpty(),
  body('schedule.endTime').optional().notEmpty(),
  body('schedule.room').optional().notEmpty(),
  body('wifiSSID').optional().notEmpty(),
  body('location.latitude').optional().isFloat(),
  body('location.longitude').optional().isFloat(),
  body('location.radius').optional().isInt({ min: 10, max: 500 }),
  body('semester').optional().notEmpty(),
  body('academicYear').optional().notEmpty()
], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const cls = await Class.findById(req.params.id);
  if (!cls) return res.status(404).json({ success: false, message: 'Class not found' });
  if (req.user.role === 'teacher' && cls.teacher.toString() !== req.user._id.toString()) {
    return res.status(403).json({ success: false, message: 'Not authorized' });
  }
  const updated = await Class.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
  res.json({ success: true, message: 'Class updated', data: updated });
});

// @desc    Archive class (teacher/admin)
// @route   PUT /api/classes/:id/archive
// @access  Private (teacher/admin)
router.put('/:id/archive', protect, authorize('teacher', 'admin'), [param('id').isMongoId()], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const cls = await Class.findById(req.params.id);
  if (!cls) return res.status(404).json({ success: false, message: 'Class not found' });
  if (req.user.role === 'teacher' && cls.teacher.toString() !== req.user._id.toString()) {
    return res.status(403).json({ success: false, message: 'Not authorized' });
  }
  const updated = await Class.findByIdAndUpdate(req.params.id, { isActive: false }, { new: true });
  res.json({ success: true, message: 'Class archived', data: updated });
});

module.exports = router;


