# 🏫 Campus Boundary Setup Guide

This guide will help you set up custom campus boundaries for your college/university to enable geofenced attendance.

## 📍 Step 1: Get Your College Coordinates

### Method 1: Using Google Maps (Recommended)
1. Open [Google Maps](https://maps.google.com)
2. Search for your college/university name
3. Right-click on the main building or center of campus
4. Click on the coordinates that appear (e.g., "12.9716, 77.5946")
5. Copy the latitude and longitude values

### Method 2: Using the App's Location Feature
1. Open the attendance app
2. Go to **Campus Management** (Teacher login required)
3. Click **"Use Current Location"** button
4. Allow location permissions when prompted
5. The app will automatically detect your current coordinates

### Method 3: Popular Indian Colleges (Pre-configured)
The app includes coordinates for popular Indian colleges:
- IIT Delhi, IIT Bombay, IIT Madras, IIT Kanpur, IIT Kharagpur
- Delhi University, JNU Delhi, Anna University
- VIT Vellore, BITS Pilani

## 🎯 Step 2: Choose Boundary Type

### 🔵 Circular Boundary (Recommended for most colleges)
- **Best for**: Most colleges and universities
- **Setup**: Center point + radius
- **Example**: 500-meter radius around main building

### 📐 Rectangular Boundary
- **Best for**: Colleges with clear rectangular campus layout
- **Setup**: Southwest corner + Northeast corner
- **Example**: Define campus corners

### 🔷 Polygon Boundary
- **Best for**: Complex campus shapes with irregular boundaries
- **Setup**: Multiple points defining campus perimeter
- **Example**: 5-10 points around campus edges

## 📏 Step 3: Set Appropriate Radius/Size

### Suggested Radius by Campus Type:
- **Small College**: 300-500 meters
- **Medium College**: 500-800 meters  
- **Large University**: 800-1200 meters
- **Campus with Multiple Buildings**: 1000-1500 meters

### How to Determine Size:
1. **Measure from center**: Use Google Maps to measure distance from campus center to farthest building
2. **Add buffer**: Add 100-200 meters buffer for accuracy
3. **Test and adjust**: Start with suggested size, then adjust based on testing

## 🛠️ Step 4: Setup in the App

### For Teachers:
1. **Login**: Use teacher credentials (`teacher@demo.com` / `password123`)
2. **Navigate**: Go to **"Campus"** button in teacher dashboard
3. **Create**: Click **"+"** or **"Add Campus Boundary"**
4. **Configure**:
   - Enter campus name (e.g., "Main Campus", "Engineering Block")
   - Add description (optional)
   - Choose boundary type
   - Enter coordinates
   - Set radius/size
5. **Test**: Use **"Test"** button to verify boundary
6. **Save**: Click **"Create"** to save

### For Students:
- No setup required
- System automatically checks against teacher-defined boundaries
- Clear error messages if outside campus area

## 🧪 Step 5: Testing Your Setup

### Test Inside Campus:
1. Login as student
2. Go to **"Mark Attendance"**
3. Try scanning QR code
4. Should work normally if inside boundary

### Test Outside Campus:
1. Move outside the defined boundary
2. Try marking attendance
3. Should see: **"You are not inside the campus area"**
4. Error dialog with helpful guidance

## 📱 Step 6: Real-World Testing

### Location Accuracy:
- **GPS Accuracy**: ±3-5 meters (good for most cases)
- **Indoor Testing**: May have reduced accuracy
- **Outdoor Testing**: More accurate results

### Common Issues & Solutions:

#### Issue: "Always outside campus"
- **Solution**: Increase radius by 100-200 meters
- **Check**: Verify coordinates are correct

#### Issue: "Can mark attendance from anywhere"
- **Solution**: Decrease radius or check boundary type
- **Check**: Ensure boundary is active

#### Issue: "Location not detected"
- **Solution**: Enable location services
- **Check**: Grant location permissions to app

## 🎨 Advanced Configuration

### Multiple Campus Boundaries:
- Create separate boundaries for different campus areas
- Example: "Main Campus", "Engineering Block", "Medical Block"
- Students can mark attendance from any active boundary

### Boundary Management:
- **Edit**: Modify existing boundaries
- **Deactivate**: Temporarily disable boundaries
- **Delete**: Remove unused boundaries
- **Test**: Verify boundary accuracy

### Real-Time Monitoring:
- Use **"Test"** feature to check current location
- Monitor geofence status in real-time
- Adjust boundaries based on actual usage

## 📊 Example Configurations

### Example 1: Small Engineering College
```
Name: "Main Campus"
Type: Circle
Center: 12.9716, 77.5946
Radius: 400 meters
Description: "Main engineering college campus"
```

### Example 2: Large University
```
Name: "University Campus"
Type: Circle  
Center: 28.5450, 77.1925
Radius: 1000 meters
Description: "Main university campus with multiple departments"
```

### Example 3: Complex Campus Layout
```
Name: "Multi-Block Campus"
Type: Polygon
Points: 
  - 12.9716, 77.5946
  - 12.9720, 77.5950
  - 12.9725, 77.5948
  - 12.9722, 77.5942
  - 12.9718, 77.5944
Description: "Campus with irregular boundary"
```

## 🔧 Troubleshooting

### Location Services Not Working:
1. Check device location settings
2. Grant location permissions to app
3. Ensure GPS is enabled
4. Try outdoor testing for better accuracy

### Boundary Not Working:
1. Verify coordinates are correct
2. Check if boundary is active
3. Test with different radius
4. Ensure proper boundary type

### App Crashes:
1. Restart the app
2. Check for app updates
3. Clear app cache
4. Reinstall if necessary

## 📞 Support

If you encounter issues:
1. Check this guide first
2. Test with demo boundaries
3. Verify your coordinates
4. Contact support with specific error messages

## 🎯 Quick Start Checklist

- [ ] Get college coordinates (Google Maps or app location)
- [ ] Choose boundary type (Circle recommended)
- [ ] Set appropriate radius (300-1500 meters)
- [ ] Login as teacher and create boundary
- [ ] Test boundary with "Test" button
- [ ] Test as student from inside/outside campus
- [ ] Adjust radius if needed
- [ ] Save and activate boundary

---

**Ready to set up your campus boundaries?** 
1. Open the app
2. Login as teacher
3. Go to Campus Management
4. Follow the steps above!

Your geofenced attendance system will be ready in minutes! 🚀
