// Check current server status safely
console.log('🔍 فحص حالة السيرفر الحالية...\n');

// Test function to check endpoints
async function checkEndpoint(url, method = 'GET', body = null) {
  try {
    const options = {
      method,
      headers: { 'Content-Type': 'application/json' }
    };
    
    if (body) {
      options.body = JSON.stringify(body);
    }
    
    const response = await fetch(url, options);
    const data = await response.json().catch(() => 'Invalid JSON');
    
    console.log(`✅ ${method} ${url}`);
    console.log(`   Status: ${response.status}`);
    console.log(`   Response: ${JSON.stringify(data).substring(0, 100)}...`);
    console.log('');
    
    return { status: response.status, data };
  } catch (error) {
    console.log(`❌ ${method} ${url}`);
    console.log(`   Error: ${error.message}`);
    console.log('');
    return { error: error.message };
  }
}

// Run checks
(async () => {
  console.log('📡 فحص Backend APIs...');
  
  // Check backend health
  await checkEndpoint('https://unibus.online:3001/health');
  
  // Check auth endpoints
  await checkEndpoint('https://unibus.online:3001/api/auth/register', 'POST', {
    email: 'test@test.com',
    password: 'test123',
    fullName: 'Test User',
    role: 'student'
  });
  
  console.log('🌐 فحص Frontend APIs...');
  
  // Check frontend proxy
  await checkEndpoint('https://unibus.online/api/proxy/auth/register', 'POST', {
    email: 'test@test.com',
    password: 'test123',
    fullName: 'Test User',
    role: 'student'
  });
  
  console.log('✅ انتهى الفحص');
})();
