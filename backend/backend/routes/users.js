const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { protect, authorize } = require('../middleware/auth');
const User = require('../models/User');

const router = express.Router();

function handleValidation(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, message: 'Validation failed', errors: errors.array() });
  }
}

// @desc    List users (admin)
// @route   GET /api/users
// @access  Private (admin)
router.get('/', protect, authorize('admin'), [
  query('role').optional().isIn(['student', 'teacher', 'admin']).withMessage('Invalid role filter'),
  query('q').optional().isString(),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('page').optional().isInt({ min: 1 })
], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const { role, q } = req.query;
  const limit = parseInt(req.query.limit || '20', 10);
  const page = parseInt(req.query.page || '1', 10);

  const filter = {};
  if (role) filter.role = role;
  if (q) filter.$or = [
    { name: new RegExp(q, 'i') },
    { email: new RegExp(q, 'i') },
    { studentId: new RegExp(q, 'i') }
  ];

  const [users, total] = await Promise.all([
    User.find(filter).sort({ createdAt: -1 }).skip((page - 1) * limit).limit(limit),
    User.countDocuments(filter)
  ]);

  res.json({ success: true, data: users, meta: { total, page, limit } });
});

// @desc    Get user by id (admin)
// @route   GET /api/users/:id
// @access  Private (admin)
router.get('/:id', protect, authorize('admin'), [
  param('id').isMongoId()
], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const user = await User.findById(req.params.id)
    .populate('enrolledClasses', 'name code subject')
    .populate('teachingClasses', 'name code subject');
  if (!user) return res.status(404).json({ success: false, message: 'User not found' });
  res.json({ success: true, data: user });
});

// @desc    Update user status (activate/deactivate)
// @route   PUT /api/users/:id/status
// @access  Private (admin)
router.put('/:id/status', protect, authorize('admin'), [
  param('id').isMongoId(),
  body('isActive').isBoolean()
], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const user = await User.findByIdAndUpdate(req.params.id, { isActive: req.body.isActive }, { new: true });
  if (!user) return res.status(404).json({ success: false, message: 'User not found' });
  res.json({ success: true, message: 'Status updated', data: user });
});

// @desc    Update user role
// @route   PUT /api/users/:id/role
// @access  Private (admin)
router.put('/:id/role', protect, authorize('admin'), [
  param('id').isMongoId(),
  body('role').isIn(['student', 'teacher', 'admin'])
], async (req, res) => {
  const invalid = handleValidation(req, res); if (invalid) return invalid;
  const user = await User.findByIdAndUpdate(req.params.id, { role: req.body.role }, { new: true });
  if (!user) return res.status(404).json({ success: false, message: 'User not found' });
  res.json({ success: true, message: 'Role updated', data: user });
});

// @desc    Get my classes (enrolled/teaching)
// @route   GET /api/users/me/classes
// @access  Private
router.get('/me/classes', protect, async (req, res) => {
  const user = await User.findById(req.user._id)
    .populate('enrolledClasses', 'name code subject teacher')
    .populate('teachingClasses', 'name code subject');
  res.json({ success: true, data: user });
});

module.exports = router;


