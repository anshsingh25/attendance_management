# Attendance Management System - Backend API

A comprehensive backend API for managing attendance using QR codes, WiFi validation, and location tracking.

## Features

- 🔐 **JWT Authentication** - Secure user authentication and authorization
- 👥 **Role-based Access** - Student, Teacher, and Admin roles
- 📱 **QR Code Generation** - Dynamic QR codes for attendance sessions
- 📍 **Location Validation** - GPS-based geofencing
- 📶 **WiFi Validation** - Classroom WiFi verification
- 📊 **Attendance Tracking** - Complete attendance management
- 🏫 **Class Management** - Course and student enrollment
- 📈 **Analytics** - Attendance reports and statistics

## Tech Stack

- **Node.js** - Runtime environment
- **Express.js** - Web framework
- **MongoDB** - Database
- **Mongoose** - ODM for MongoDB
- **JWT** - Authentication
- **QRCode** - QR code generation
- **Bcrypt** - Password hashing

## Installation

1. **Clone the repository**
   ```bash
   cd backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment Setup**
   ```bash
   cp env.example .env
   ```
   
   Update the `.env` file with your configuration:
   ```env
   MONGODB_URI=mongodb://localhost:27017/attendance_system
   JWT_SECRET=your_super_secret_jwt_key_here
   PORT=5000
   NODE_ENV=development
   ```

4. **Start MongoDB**
   ```bash
   # Using MongoDB service
   sudo systemctl start mongod
   
   # Or using Docker
   docker run -d -p 27017:27017 --name mongodb mongo:latest
   ```

5. **Run the application**
   ```bash
   # Development mode
   npm run dev
   
   # Production mode
   npm start
   ```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `GET /api/auth/me` - Get current user
- `PUT /api/auth/profile` - Update profile
- `PUT /api/auth/change-password` - Change password

### QR Code Management
- `POST /api/qr/generate` - Generate QR code (Teacher)
- `POST /api/qr/validate` - Validate QR code (Student)
- `GET /api/qr/active-sessions` - Get active sessions (Teacher)
- `PUT /api/qr/end-session/:id` - End session (Teacher)

### Class Management
- `GET /api/classes` - Get classes
- `POST /api/classes` - Create class (Teacher/Admin)
- `GET /api/classes/:id` - Get class details
- `PUT /api/classes/:id` - Update class
- `DELETE /api/classes/:id` - Delete class

### Attendance
- `GET /api/attendance` - Get attendance records
- `POST /api/attendance` - Mark attendance
- `GET /api/attendance/student/:id` - Get student attendance
- `GET /api/attendance/class/:id` - Get class attendance
- `GET /api/attendance/reports` - Get attendance reports

### Users
- `GET /api/users` - Get users (Admin)
- `GET /api/users/:id` - Get user details
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

## Database Schema

### User Model
```javascript
{
  name: String,
  email: String (unique),
  password: String (hashed),
  role: String (student/teacher/admin),
  studentId: String (unique, for students),
  department: String,
  semester: String,
  phone: String,
  isActive: Boolean,
  enrolledClasses: [ObjectId],
  teachingClasses: [ObjectId]
}
```

### Class Model
```javascript
{
  name: String,
  code: String (unique),
  subject: String,
  teacher: ObjectId,
  students: [ObjectId],
  schedule: {
    days: [String],
    startTime: String,
    endTime: String,
    room: String,
    building: String
  },
  wifiSSID: String,
  location: {
    latitude: Number,
    longitude: Number,
    radius: Number
  }
}
```

### Session Model
```javascript
{
  class: ObjectId,
  teacher: ObjectId,
  date: Date,
  startTime: Date,
  endTime: Date,
  qrCode: {
    data: String,
    expiresAt: Date,
    isActive: Boolean
  },
  status: String,
  attendanceWindow: {
    start: Date,
    end: Date
  },
  totalStudents: Number,
  presentCount: Number,
  lateCount: Number,
  absentCount: Number
}
```

### Attendance Model
```javascript
{
  student: ObjectId,
  class: ObjectId,
  session: ObjectId,
  status: String (present/late/absent/excused),
  markedAt: Date,
  location: {
    latitude: Number,
    longitude: Number,
    accuracy: Number
  },
  wifiSSID: String,
  deviceInfo: Object,
  verificationMethod: String,
  isVerified: Boolean
}
```

## Security Features

- **JWT Authentication** - Secure token-based authentication
- **Password Hashing** - Bcrypt with salt rounds
- **Rate Limiting** - Prevent API abuse
- **CORS Protection** - Cross-origin request security
- **Input Validation** - Express-validator for data validation
- **Helmet** - Security headers
- **Role-based Authorization** - Access control

## Deployment

### Using PM2
```bash
npm install -g pm2
pm2 start server.js --name attendance-api
pm2 startup
pm2 save
```

### Using Docker
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
```

### Environment Variables for Production
```env
NODE_ENV=production
MONGODB_URI=mongodb://your-production-db
JWT_SECRET=your-production-secret
PORT=5000
CORS_ORIGIN=https://your-frontend-domain.com
```

## Testing

```bash
# Run tests
npm test

# Run tests with coverage
npm run test:coverage
```

## API Documentation

The API follows RESTful conventions and returns JSON responses:

### Success Response Format
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

### Error Response Format
```json
{
  "success": false,
  "message": "Error description",
  "errors": [ ... ] // Validation errors if any
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see LICENSE file for details
