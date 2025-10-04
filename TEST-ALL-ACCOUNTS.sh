#!/bin/bash

echo "🧪 اختبار جميع حسابات Admin و Supervisor"
echo "=========================================="

# Test login function
test_login() {
  local email=$1
  local password=$2
  local name=$3
  
  echo ""
  echo "Testing: $name"
  echo "Email: $email"
  
  response=$(curl -s -X POST "http://localhost:3001/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$email\",\"password\":\"$password\"}")
  
  success=$(echo $response | grep -o '"success":\s*true' | wc -l)
  role=$(echo $response | jq -r '.user.role' 2>/dev/null)
  token=$(echo $response | jq -r '.token' 2>/dev/null | cut -c1-30)
  
  if [ $success -gt 0 ]; then
    echo "✅ Login Successful!"
    echo "   Role: $role"
    echo "   Token: ${token}..."
  else
    echo "❌ Login Failed!"
    echo "   Response: $response"
  fi
}

echo ""
echo "👥 Testing SUPERVISOR Accounts..."
echo "================================="

test_login "sasasona@gmail.com" "Sons123" "Mostafa sona"
test_login "Vodojoe123@gmail.com" "Vodx123" "Vodo joe"
test_login "Zoma144@gmail.com" "Mezo001" "Mazen Zoma"
test_login "Islam123@gmail.com" "islamzero123" "islamuni"
test_login "Abuzaid123@gmail.com" "Abuz002" "Mohamed Abuzaid"
test_login "omarRedatuning@gmail.com" "omarReda123" "Omar Reda"

echo ""
echo ""
echo "👑 Testing ADMIN Accounts..."
echo "============================"

test_login "Azabuni123@gmail.com" "Unibus00444" "AzabunibusAdmin"
test_login "SonaUni333@gmail.com" "Mostafuni0707" "SonaunibusAdmin"

echo ""
echo ""
echo "📊 Summary from Database:"
echo "========================="

mongosh student_portal --quiet --eval '
var supervisors = db.users.find({role: "supervisor"}).toArray();
var admins = db.users.find({role: "admin"}).toArray();

print("👥 Supervisors: " + supervisors.length);
supervisors.forEach(function(u) {
  print("  " + u.fullName + " - " + u.email);
});

print("\n👑 Admins: " + admins.length);
admins.forEach(function(u) {
  print("  " + u.fullName + " - " + u.email);
});
'

echo ""
echo "✅ اختبار السيرفر اكتمل!"
echo ""
echo "📱 الآن اختبر في المتصفح:"
echo "  🔗 unibus.online/login"
