# 🚌 UniBus Complete System Data Flow Diagram

## 📊 SYSTEM ARCHITECTURE OVERVIEW

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                 🚌 UNIBUS STUDENT PORTAL                                  │
│                              Complete Transportation Management System                     │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              🌐 ENTRY POINT & ROUTING                                    │
│                                                                                         │
│  📱 Homepage (/)  ─────────────────────► 🚀 "Enter Portal" Button                      │
│                                                    │                                     │
│                                                    ▼                                     │
│                              🔐 UNIFIED AUTH SYSTEM (/auth)                            │
│                                                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────────┐                │
│  │   LOGIN     │  │  REGISTER   │  │        ROLE SELECTOR            │                │
│  │             │  │             │  │                                 │                │
│  │ Email       │  │ Email       │  │ 🎓 Student                      │                │
│  │ Password    │  │ Password    │  │ 👨‍💼 Admin                        │                │
│  │ Role        │  │ Full Name   │  │ 👨‍🏫 Supervisor                   │                │
│  │             │  │ Role        │  │                                 │                │
│  └─────────────┘  └─────────────┘  └─────────────────────────────────┘                │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                🗄️ DATABASE LAYER                                        │
│                              MongoDB: student-portal                                   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                        📋 UNIFIED USERS COLLECTION                             │   │
│  │                                                                               │   │
│  │  👨‍💼 ADMIN USERS           👨‍🏫 SUPERVISOR USERS       🎓 STUDENT USERS          │   │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐          │   │
│  │  │ email           │    │ email           │    │ email           │          │   │
│  │  │ password (hash) │    │ password (hash) │    │ password (hash) │          │   │
│  │  │ role: 'admin'   │    │ role:'supervisor'│    │ role: 'student' │          │   │
│  │  │ fullName        │    │ fullName        │    │ fullName        │          │   │
│  │  │ permissions[]   │    │ permissions[]   │    │ studentId       │          │   │
│  │  │ isActive        │    │ isActive        │    │ college         │          │   │
│  │  │ createdAt       │    │ createdAt       │    │ grade           │          │   │
│  │  │ updatedAt       │    │ updatedAt       │    │ major           │          │   │
│  │  └─────────────────┘    └─────────────────┘    │ isActive        │          │   │
│  │                                                │ createdAt       │          │   │
│  │                                                │ updatedAt       │          │   │
│  │                                                └─────────────────┘          │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                      📊 OPERATIONAL COLLECTIONS                                │   │
│  │                                                                               │   │
│  │  📚 students          📋 attendance         💳 subscriptions                  │   │
│  │  ┌─────────────┐     ┌─────────────┐      ┌─────────────┐                    │   │
│  │  │ studentId   │     │ studentId   │      │ studentId   │                    │   │
│  │  │ fullName    │     │ supervisorId│      │ amount      │                    │   │
│  │  │ email       │     │ timestamp   │      │ paymentDate │                    │   │
│  │  │ college     │     │ location    │      │ status      │                    │   │
│  │  │ grade       │     │ status      │      │ period      │                    │   │
│  │  │ major       │     │ qrScanned   │      │ createdAt   │                    │   │
│  │  │ qrCode      │     │ createdAt   │      │ updatedAt   │                    │   │
│  │  │ profilePhoto│     │ updatedAt   │      └─────────────┘                    │   │
│  │  └─────────────┘     └─────────────┘                                         │   │
│  │                                                                               │   │
│  │  🎫 support-tickets   🚌 transportation    💸 expenses                       │   │
│  │  ┌─────────────┐     ┌─────────────┐      ┌─────────────┐                    │   │
│  │  │ studentId   │     │ routeId     │      │ type        │                    │   │
│  │  │ subject     │     │ departure   │      │ amount      │                    │   │
│  │  │ message     │     │ destination │      │ description │                    │   │
│  │  │ status      │     │ schedule    │      │ date        │                    │   │
│  │  │ priority    │     │ capacity    │      │ createdBy   │                    │   │
│  │  │ response    │     │ driver      │      │ createdAt   │                    │   │
│  │  │ createdAt   │     │ isActive    │      │ updatedAt   │                    │   │
│  │  │ updatedAt   │     │ createdAt   │      └─────────────┘                    │   │
│  │  └─────────────┘     │ updatedAt   │                                         │   │
│  │                     └─────────────┘                                         │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                  🔌 API LAYER                                            │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                           🔐 AUTHENTICATION APIs                               │   │
│  │                                                                               │   │
│  │  /api/auth/login          /api/auth/register                                  │   │
│  │  ┌─────────────────┐     ┌─────────────────┐                                 │   │
│  │  │ ✓ Validates     │     │ ✓ Creates user  │                                 │   │
│  │  │   credentials   │     │ ✓ Hashes pwd    │                                 │   │
│  │  │ ✓ Checks role   │     │ ✓ Sets role     │                                 │   │
│  │  │ ✓ Returns JWT   │     │ ✓ Returns JWT   │                                 │   │
│  │  │ ✓ User data     │     │ ✓ User data     │                                 │   │
│  │  └─────────────────┘     └─────────────────┘                                 │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                         📊 ATTENDANCE MANAGEMENT APIs                          │   │
│  │                                                                               │   │
│  │  /api/attendance/register    /api/attendance/records    /api/attendance/scan-qr│   │
│  │  ┌─────────────────┐        ┌─────────────────┐        ┌─────────────────┐   │   │
│  │  │ ✓ QR Code scan  │        │ ✓ Get records   │        │ ✓ Real-time     │   │   │
│  │  │ ✓ Duplicate     │        │ ✓ Filter by     │        │   scanning      │   │   │
│  │  │   prevention    │        │   date/student  │        │ ✓ Concurrent    │   │   │
│  │  │ ✓ Supervisor    │        │ ✓ Pagination    │        │   support       │   │   │
│  │  │   verification  │        │ ✓ Export data   │        │ ✓ Validation    │   │   │
│  │  │ ✓ Timestamp     │        │ ✓ Statistics    │        │ ✓ Auto-record   │   │   │
│  │  └─────────────────┘        └─────────────────┘        └─────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                          👥 STUDENT MANAGEMENT APIs                            │   │
│  │                                                                               │   │
│  │  /api/students/profile   /api/students/search   /api/students/generate-qr     │   │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐           │   │
│  │  │ ✓ Get profile   │    │ ✓ Search by     │    │ ✓ Generate QR   │           │   │
│  │  │ ✓ Update data   │    │   name/email    │    │ ✓ Unique codes  │           │   │
│  │  │ ✓ Photo upload  │    │ ✓ Filter by     │    │ ✓ Student data  │           │   │
│  │  │ ✓ QR generation │    │   college/grade │    │ ✓ Secure format │           │   │
│  │  │ ✓ Validation    │    │ ✓ Pagination    │    │ ✓ PNG/SVG       │           │   │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘           │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                        💳 SUBSCRIPTION & PAYMENT APIs                          │   │
│  │                                                                               │   │
│  │  /api/subscription/payment   /api/expenses/route   /api/driver-salaries       │   │
│  │  ┌─────────────────┐        ┌─────────────────┐   ┌─────────────────┐        │   │
│  │  │ ✓ Process       │        │ ✓ Track         │   │ ✓ Manage driver │        │   │
│  │  │   payments      │        │   expenses      │   │   salaries      │        │   │
│  │  │ ✓ Validate      │        │ ✓ Categories    │   │ ✓ Monthly pay   │        │   │
│  │  │   amounts       │        │ ✓ Reports       │   │ ✓ Bonus system  │        │   │
│  │  │ ✓ Generate      │        │ ✓ Budgeting     │   │ ✓ Performance   │        │   │
│  │  │   receipts      │        │ ✓ Analytics     │   │   tracking      │        │   │
│  │  └─────────────────┘        └─────────────────┘   └─────────────────┘        │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                         🚌 TRANSPORTATION & SUPPORT APIs                       │   │
│  │                                                                               │   │
│  │  /api/transportation     /api/support/tickets    /api/shifts                  │   │
│  │  ┌─────────────────┐    ┌─────────────────┐     ┌─────────────────┐          │   │
│  │  │ ✓ Route mgmt    │    │ ✓ Create        │     │ ✓ Shift mgmt    │          │   │
│  │  │ ✓ Schedule      │    │   tickets       │     │ ✓ Supervisor    │          │   │
│  │  │ ✓ Capacity      │    │ ✓ Track status  │     │   assignment    │          │   │
│  │  │ ✓ Driver        │    │ ✓ Responses     │     │ ✓ Time tracking │          │   │
│  │  │   assignment    │    │ ✓ Priority      │     │ ✓ Attendance    │          │   │
│  │  │ ✓ Real-time     │    │   levels        │     │   correlation   │          │   │
│  │  │   updates       │    │ ✓ Auto-resolve  │     │ ✓ Reporting     │          │   │
│  │  └─────────────────┘    └─────────────────┘     └─────────────────┘          │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              🖥️ USER INTERFACE LAYER                                     │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                           👨‍💼 ADMIN DASHBOARD                                      │   │
│  │                                                                                 │   │
│  │  📊 Main Dashboard        👥 User Management       📈 Reports & Analytics       │   │
│  │  ┌─────────────────┐     ┌─────────────────┐      ┌─────────────────┐         │   │
│  │  │ ✓ System stats  │     │ ✓ Add/Edit      │      │ ✓ Attendance    │         │   │
│  │  │ ✓ Quick actions │     │   users         │      │   reports       │         │   │
│  │  │ ✓ Recent        │     │ ✓ Role mgmt     │      │ ✓ Financial     │         │   │
│  │  │   activity      │     │ ✓ Student       │      │   analysis      │         │   │
│  │  │ ✓ Alerts &      │     │   search        │      │ ✓ Performance   │         │   │
│  │  │   notifications │     │ ✓ Bulk actions  │      │   metrics       │         │   │
│  │  │ ✓ Revenue       │     │ ✓ Profile mgmt  │      │ ✓ Export data   │         │   │
│  │  │   tracking      │     │ ✓ Permissions   │      │ ✓ Visual charts │         │   │
│  │  └─────────────────┘     └─────────────────┘      └─────────────────┘         │   │
│  │                                                                                 │   │
│  │  💳 Subscription Mgmt     🚌 Transportation        🎧 Support Center           │   │
│  │  ┌─────────────────┐     ┌─────────────────┐      ┌─────────────────┐         │   │
│  │  │ ✓ Payment       │     │ ✓ Route         │      │ ✓ Ticket mgmt   │         │   │
│  │  │   processing    │     │   management    │      │ ✓ Response      │         │   │
│  │  │ ✓ Billing       │     │ ✓ Schedule      │      │   system        │         │   │
│  │  │   cycles        │     │   creation      │      │ ✓ Priority      │         │   │
│  │  │ ✓ Revenue       │     │ ✓ Driver        │      │   handling      │         │   │
│  │  │   reports       │     │   assignment    │      │ ✓ Auto          │         │   │
│  │  │ ✓ Refunds       │     │ ✓ Capacity      │      │   responses     │         │   │
│  │  │ ✓ Pricing       │     │   monitoring    │      │ ✓ Escalation    │         │   │
│  │  └─────────────────┘     └─────────────────┘      └─────────────────┘         │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                         👨‍🏫 SUPERVISOR DASHBOARD                                 │   │
│  │                                                                                 │   │
│  │  📱 QR Code Scanner       📋 Attendance Mgmt       📊 Shift Management         │   │
│  │  ┌─────────────────┐     ┌─────────────────┐      ┌─────────────────┐         │   │
│  │  │ ✓ Real-time     │     │ ✓ Mark          │      │ ✓ Start/End     │         │   │
│  │  │   scanning      │     │   attendance    │      │   shifts        │         │   │
│  │  │ ✓ Concurrent    │     │ ✓ View records  │      │ ✓ Break         │         │   │
│  │  │   support       │     │ ✓ Edit entries  │      │   management    │         │   │
│  │  │ ✓ Auto          │     │ ✓ Export data   │      │ ✓ Time          │         │   │
│  │  │   validation    │     │ ✓ Statistics    │      │   tracking      │         │   │
│  │  │ ✓ Duplicate     │     │ ✓ Student       │      │ ✓ Performance   │         │   │
│  │  │   prevention    │     │   verification  │      │   monitoring    │         │   │
│  │  │ ✓ Offline mode  │     │ ✓ Bulk updates  │      │ ✓ Reporting     │         │   │
│  │  └─────────────────┘     └─────────────────┘      └─────────────────┘         │   │
│  │                                                                                 │   │
│  │  💰 Payment Processing    📈 Reports               🔧 Quick Actions             │   │
│  │  ┌─────────────────┐     ┌─────────────────┐      ┌─────────────────┐         │   │
│  │  │ ✓ Collect       │     │ ✓ Daily         │      │ ✓ Add expense   │         │   │
│  │  │   payments      │     │   summaries     │      │ ✓ Driver salary │         │   │
│  │  │ ✓ Cash/Digital  │     │ ✓ Attendance    │      │ ✓ Emergency     │         │   │
│  │  │ ✓ Receipt       │     │   rates         │      │   contact       │         │   │
│  │  │   generation    │     │ ✓ Revenue       │      │ ✓ Student       │         │   │
│  │  │ ✓ Change        │     │   tracking      │      │   lookup        │         │   │
│  │  │   management    │     │ ✓ Performance   │      │ ✓ Route info    │         │   │
│  │  └─────────────────┘     └─────────────────┘      └─────────────────┘         │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                           🎓 STUDENT PORTAL                                     │   │
│  │                                                                                 │   │
│  │  👤 Profile Management    📝 Registration          💳 Subscription Mgmt        │   │
│  │  ┌─────────────────┐     ┌─────────────────┐      ┌─────────────────┐         │   │
│  │  │ ✓ Personal info │     │ ✓ Transport     │      │ ✓ Payment       │         │   │
│  │  │ ✓ Photo upload  │     │   registration  │      │   history       │         │   │
│  │  │ ✓ Contact       │     │ ✓ Route         │      │ ✓ Current plan  │         │   │
│  │  │   details       │     │   selection     │      │ ✓ Billing       │         │   │
│  │  │ ✓ Academic      │     │ ✓ Schedule      │      │   cycles        │         │   │
│  │  │   information   │     │   preferences   │      │ ✓ Upgrade/      │         │   │
│  │  │ ✓ QR code       │     │ ✓ Special       │      │   Downgrade     │         │   │
│  │  │   generation    │     │   requirements  │      │ ✓ Auto-renewal  │         │   │
│  │  └─────────────────┘     └─────────────────┘      └─────────────────┘         │   │
│  │                                                                                 │   │
│  │  🚌 Transportation        🎧 Support Center        📊 My Statistics            │   │
│  │  ┌─────────────────┐     ┌─────────────────┐      ┌─────────────────┐         │   │
│  │  │ ✓ Route info    │     │ ✓ Submit        │      │ ✓ Attendance    │         │   │
│  │  │ ✓ Schedule      │     │   tickets       │      │   history       │         │   │
│  │  │ ✓ Real-time     │     │ ✓ Track status  │      │ ✓ Payment       │         │   │
│  │  │   tracking      │     │ ✓ Chat support  │      │   records       │         │   │
│  │  │ ✓ Notifications │     │ ✓ FAQ section   │      │ ✓ Route usage   │         │   │
│  │  │ ✓ Map           │     │ ✓ Contact info  │      │ ✓ Performance   │         │   │
│  │  │   integration   │     │ ✓ Feedback      │      │   metrics       │         │   │
│  │  │ ✓ Alerts        │     │   system        │      │ ✓ Reports       │         │   │
│  │  └─────────────────┘     └─────────────────┘      └─────────────────┘         │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

## 🔄 COMPLETE DATA FLOW PROCESSES

### 1. **AUTHENTICATION & AUTHORIZATION FLOW**
```
User Access → Homepage → "Enter Portal" → /auth page
    ↓
Select Role (Student/Admin/Supervisor) → Enter Credentials
    ↓
POST /api/auth/login → Database Query → Password Validation
    ↓
JWT Generation → localStorage Storage → Role-based Redirect
    ↓
🎓 Student → /student/portal
👨‍💼 Admin → /admin/dashboard  
👨‍🏫 Supervisor → /admin/supervisor-dashboard
```

### 2. **STUDENT REGISTRATION PROCESS**
```
Student Portal → Registration → Fill Form Data
    ↓
POST /api/students/register → Validation → Database Insert
    ↓
QR Code Generation → Profile Photo Upload → Email Confirmation
    ↓
Account Activation → Transportation Selection → Payment Setup
```

### 3. **ATTENDANCE MANAGEMENT FLOW**
```
Supervisor Login → QR Scanner Activation → Student QR Scan
    ↓
POST /api/attendance/scan-qr → Student Verification → Duplicate Check
    ↓
Attendance Record Creation → Real-time Update → Statistics Update
    ↓
Notification → Parent SMS → Admin Dashboard Update
```

### 4. **PAYMENT & SUBSCRIPTION FLOW**
```
Student → Subscription Management → Select Plan → Payment Method
    ↓
POST /api/subscription/payment → Payment Gateway → Transaction Validation
    ↓
Receipt Generation → Database Update → Service Activation
    ↓
Billing Cycle Setup → Auto-renewal → Payment History
```

### 5. **TRANSPORTATION MANAGEMENT FLOW**
```
Admin → Transportation → Route Creation → Schedule Setup
    ↓
Driver Assignment → Capacity Management → Student Assignment
    ↓
Real-time Tracking → GPS Integration → ETA Calculations
    ↓
Notifications → Route Optimization → Performance Analytics
```

### 6. **SUPPORT SYSTEM FLOW**
```
Student/User → Support Center → Create Ticket → Priority Assignment
    ↓
Ticket Routing → Admin/Supervisor Assignment → Response Generation
    ↓
Status Updates → Resolution Tracking → Satisfaction Survey
    ↓
Knowledge Base Update → FAQ Generation → Auto-resolution
```

### 7. **REPORTING & ANALYTICS FLOW**
```
System Data Collection → Real-time Aggregation → Statistical Analysis
    ↓
Report Generation → Visual Charts → Export Functions
    ↓
Performance Metrics → Trend Analysis → Predictive Insights
    ↓
Decision Support → Optimization Recommendations → Action Items
```

## 🔐 SECURITY & VALIDATION LAYERS

### **Authentication Security:**
- JWT Token Validation
- Password Hashing (bcrypt)
- Role-based Access Control
- Session Management
- Brute Force Protection

### **Data Validation:**
- Input Sanitization
- XSS Prevention
- SQL Injection Protection
- File Upload Validation
- Rate Limiting

### **API Security:**
- CORS Configuration
- Request Validation
- Error Handling
- Audit Logging
- Encryption at Rest

## 📊 SYSTEM PERFORMANCE METRICS

### **Key Performance Indicators:**
- **User Engagement:** Login frequency, session duration
- **Attendance Accuracy:** QR scan success rate, duplicate prevention
- **Payment Processing:** Transaction success rate, processing time
- **Support Efficiency:** Ticket resolution time, satisfaction scores
- **System Reliability:** Uptime, response time, error rates

### **Real-time Monitoring:**
- Database Performance
- API Response Times
- User Activity Tracking
- Error Rate Monitoring
- Resource Utilization

## 🚀 SYSTEM INTEGRATIONS

### **External Services:**
- **Payment Gateway:** Secure transaction processing
- **SMS Service:** Notifications and alerts
- **Email Service:** Confirmations and updates
- **Maps API:** Route optimization and tracking
- **Cloud Storage:** File uploads and backups

### **Internal Integrations:**
- **QR Code Library:** Student identification
- **PDF Generation:** Reports and receipts
- **Image Processing:** Profile photos and compression
- **Notification System:** Real-time alerts
- **Backup System:** Data protection and recovery

## ✅ SYSTEM VERIFICATION CHECKLIST

### **✅ CORE FEATURES VERIFIED:**
- [x] Unified authentication system
- [x] Role-based access control
- [x] QR code attendance tracking
- [x] Payment processing
- [x] Transportation management
- [x] Support ticket system
- [x] Real-time reporting
- [x] Mobile responsiveness

### **✅ DATA INTEGRITY:**
- [x] Unified user database
- [x] Consistent data relationships
- [x] Backup and recovery systems
- [x] Transaction logging
- [x] Data validation rules

### **✅ SECURITY MEASURES:**
- [x] Secure authentication
- [x] Encrypted data storage
- [x] Input validation
- [x] Access control
- [x] Audit trails

## 🎯 SYSTEM STATUS: PRODUCTION READY ✅

**All components integrated and fully functional!** 🚌✨
