const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Import models
const User = require('../models/User');
const Class = require('../models/Class');

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/attendance_system');
    console.log('MongoDB Connected');
  } catch (error) {
    console.error('Database connection error:', error);
    process.exit(1);
  }
};

const setupInitialData = async () => {
  try {
    console.log('Setting up initial data...');

    // Create admin user
    const adminExists = await User.findOne({ email: 'admin@demo.com' });
    if (!adminExists) {
      const admin = await User.create({
        name: 'System Administrator',
        email: 'admin@demo.com',
        password: 'password123',
        role: 'admin',
        department: 'IT',
        phone: '+1234567890'
      });
      console.log('✅ Admin user created:', admin.email);
    } else {
      console.log('ℹ️  Admin user already exists');
    }

    // Create teacher user
    const teacherExists = await User.findOne({ email: 'teacher@demo.com' });
    if (!teacherExists) {
      const teacher = await User.create({
        name: 'Dr. John Smith',
        email: 'teacher@demo.com',
        password: 'password123',
        role: 'teacher',
        department: 'Computer Science',
        phone: '+1234567891'
      });
      console.log('✅ Teacher user created:', teacher.email);
    } else {
      console.log('ℹ️  Teacher user already exists');
    }

    // Create student users
    const students = [
      {
        name: 'Alice Johnson',
        email: 'student@demo.com',
        password: 'password123',
        role: 'student',
        studentId: 'STU001',
        department: 'Computer Science',
        semester: '3rd',
        phone: '+1234567892'
      },
      {
        name: 'Bob Wilson',
        email: 'bob@demo.com',
        password: 'password123',
        role: 'student',
        studentId: 'STU002',
        department: 'Computer Science',
        semester: '3rd',
        phone: '+1234567893'
      },
      {
        name: 'Carol Davis',
        email: 'carol@demo.com',
        password: 'password123',
        role: 'student',
        studentId: 'STU003',
        department: 'Computer Science',
        semester: '3rd',
        phone: '+1234567894'
      }
    ];

    for (const studentData of students) {
      const studentExists = await User.findOne({ email: studentData.email });
      if (!studentExists) {
        const student = await User.create(studentData);
        console.log('✅ Student user created:', student.email);
      } else {
        console.log('ℹ️  Student user already exists:', studentData.email);
      }
    }

    // Get teacher and students for class creation
    const teacher = await User.findOne({ email: 'teacher@demo.com' });
    const studentUsers = await User.find({ role: 'student' });

    // Create sample classes
    const classes = [
      {
        name: 'Mathematics 101',
        code: 'MATH101',
        subject: 'Mathematics',
        teacher: teacher._id,
        students: studentUsers.map(s => s._id),
        schedule: {
          days: ['monday', 'wednesday', 'friday'],
          startTime: '09:00',
          endTime: '10:30',
          room: 'Room 101',
          building: 'Building A'
        },
        wifiSSID: 'Classroom_WiFi_101',
        location: {
          latitude: 40.7128,
          longitude: -74.0060,
          radius: 50
        },
        semester: 'Fall 2024',
        academicYear: '2024-2025'
      },
      {
        name: 'Physics 201',
        code: 'PHYS201',
        subject: 'Physics',
        teacher: teacher._id,
        students: studentUsers.map(s => s._id),
        schedule: {
          days: ['tuesday', 'thursday'],
          startTime: '10:30',
          endTime: '12:00',
          room: 'Room 102',
          building: 'Building A'
        },
        wifiSSID: 'Classroom_WiFi_102',
        location: {
          latitude: 40.7128,
          longitude: -74.0060,
          radius: 50
        },
        semester: 'Fall 2024',
        academicYear: '2024-2025'
      },
      {
        name: 'Chemistry 301',
        code: 'CHEM301',
        subject: 'Chemistry',
        teacher: teacher._id,
        students: studentUsers.map(s => s._id),
        schedule: {
          days: ['monday', 'wednesday'],
          startTime: '14:00',
          endTime: '15:30',
          room: 'Room 103',
          building: 'Building B'
        },
        wifiSSID: 'Classroom_WiFi_103',
        location: {
          latitude: 40.7128,
          longitude: -74.0060,
          radius: 50
        },
        semester: 'Fall 2024',
        academicYear: '2024-2025'
      }
    ];

    for (const classData of classes) {
      const classExists = await Class.findOne({ code: classData.code });
      if (!classExists) {
        const newClass = await Class.create(classData);
        console.log('✅ Class created:', newClass.name);
      } else {
        console.log('ℹ️  Class already exists:', classData.name);
      }
    }

    // Update user enrolled/teaching classes
    const createdClasses = await Class.find();
    
    // Update teacher's teaching classes
    await User.findByIdAndUpdate(teacher._id, {
      teachingClasses: createdClasses.map(c => c._id)
    });

    // Update students' enrolled classes
    for (const student of studentUsers) {
      await User.findByIdAndUpdate(student._id, {
        enrolledClasses: createdClasses.map(c => c._id)
      });
    }

    console.log('✅ Setup completed successfully!');
    console.log('\n📋 Demo Credentials:');
    console.log('Admin: admin@demo.com / password123');
    console.log('Teacher: teacher@demo.com / password123');
    console.log('Student: student@demo.com / password123');
    console.log('Student: bob@demo.com / password123');
    console.log('Student: carol@demo.com / password123');

  } catch (error) {
    console.error('Setup error:', error);
  }
};

const main = async () => {
  await connectDB();
  await setupInitialData();
  process.exit(0);
};

main();
