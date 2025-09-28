// Test script to check registration functionality
const testRegistration = async () => {
  const testUser = {
    email: `test_student_${Date.now()}@unibus.com`,
    password: 'testpassword123',
    fullName: 'Test Student',
    role: 'student'
  };
  
  console.log('🧪 Testing registration with:', testUser);
  
  try {
    // Test direct backend registration
    const response = await fetch('https://unibus.online:3001/api/auth/register', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(testUser)
    });
    
    const data = await response.json();
    
    console.log('📡 Backend Response Status:', response.status);
    console.log('📋 Backend Response Data:', data);
    
    if (data.success) {
      console.log('✅ Registration successful!');
      console.log('🎫 Token:', data.token);
      console.log('👤 User:', data.user);
      
      // Test login with the same credentials
      console.log('\n🔐 Testing login with registered user...');
      
      const loginResponse = await fetch('https://unibus.online:3001/api/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          email: testUser.email,
          password: testUser.password,
          role: testUser.role
        })
      });
      
      const loginData = await loginResponse.json();
      console.log('🔐 Login Response:', loginData);
      
    } else {
      console.log('❌ Registration failed:', data.message);
    }
    
  } catch (error) {
    console.error('❌ Test error:', error);
  }
};

// Run the test
testRegistration();
