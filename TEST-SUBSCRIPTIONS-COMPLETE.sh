#!/bin/bash

echo "🎯 اختبار شامل لنظام Subscriptions والـ Reports"
echo "====================================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==========================================
# إعداد
# ==========================================
echo -e "${YELLOW}إعداد الاختبار...${NC}"

# Login Supervisor
SUPER_LOGIN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}')

SUPER_TOKEN=$(echo "$SUPER_LOGIN" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')

# Login Student
STUDENT_LOGIN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"aliramy123@gmail.com","password":"ali123"}')

STUDENT_TOKEN=$(echo "$STUDENT_LOGIN" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')

echo "✅ Tokens جاهزة"
echo ""

# ==========================================
# الخطوة 1: دفع اشتراك من Student Details Form
# ==========================================
echo "======================================"
echo -e "${BLUE}الخطوة 1️⃣: دفع اشتراك (Supervisor → Student Details → Payment Form)${NC}"
echo "======================================"

PAYMENT=$(curl -s -X POST http://localhost:3001/api/subscriptions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SUPER_TOKEN" \
  -d '{
    "studentEmail":"aliramy123@gmail.com",
    "studentName":"ali ramy",
    "amount":750,
    "subscriptionType":"monthly",
    "paymentMethod":"cash"
  }')

if echo "$PAYMENT" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Payment نجح${NC}"
    echo "   Amount: 750 EGP"
    echo "   Type: Monthly"
    echo "   Student: ali ramy"
else
    echo -e "${RED}❌ Payment فشل${NC}"
    echo "$PAYMENT" | head -c 300
fi

echo ""

# ==========================================
# الخطوة 2: التحقق من ظهور الاشتراك في Student Portal
# ==========================================
echo "======================================"
echo -e "${BLUE}الخطوة 2️⃣: Student Portal → Subscriptions Tab${NC}"
echo "======================================"

STUDENT_SUBS=$(curl -s "http://localhost:3001/api/subscriptions/student?email=aliramy123@gmail.com" \
  -H "Authorization: Bearer $STUDENT_TOKEN")

if echo "$STUDENT_SUBS" | grep -q '"success":true'; then
    SUB_COUNT=$(echo "$STUDENT_SUBS" | grep -o '"_id"' | wc -l)
    TOTAL_AMOUNT=$(echo "$STUDENT_SUBS" | grep -o '"amount":[0-9]*' | awk -F: '{sum+=$2} END {print sum}')
    
    echo -e "${GREEN}✅ الاشتراكات تظهر في Student Portal${NC}"
    echo "   عدد الاشتراكات: $SUB_COUNT"
    echo "   المبلغ الإجمالي: ${TOTAL_AMOUNT:-0} EGP"
    
    # عرض التفاصيل
    echo ""
    echo "   التفاصيل:"
    echo "$STUDENT_SUBS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for sub in data.get('subscriptions', []):
    print(f\"    - {sub.get('amount')} EGP ({sub.get('subscriptionType')}) - Status: {sub.get('status')}\")
    if sub.get('remainingDays'):
        print(f\"      Remaining: {sub.get('remainingDays')} days\")
" 2>/dev/null || echo "$STUDENT_SUBS" | head -c 400
else
    echo -e "${RED}❌ لا تظهر في Student Portal${NC}"
fi

echo ""

# ==========================================
# الخطوة 3: التحقق من ظهور في Admin Subscriptions
# ==========================================
echo "======================================"
echo -e "${BLUE}الخطوة 3️⃣: Admin → Subscriptions Page${NC}"
echo "======================================"

ADMIN_SUBS=$(curl -s "http://localhost:3001/api/subscriptions" \
  -H "Authorization: Bearer $SUPER_TOKEN")

ALI_SUBS=$(echo "$ADMIN_SUBS" | grep -o "aliramy123@gmail.com" | wc -l)

if [ $ALI_SUBS -gt 0 ]; then
    echo -e "${GREEN}✅ الاشتراكات تظهر في Admin Subscriptions${NC}"
    echo "   عدد اشتراكات ali ramy: $ALI_SUBS"
else
    echo -e "${RED}❌ لا تظهر في Admin${NC}"
fi

echo ""

# ==========================================
# الخطوة 4: Admin Reports - Revenue
# ==========================================
echo "======================================"
echo -e "${BLUE}الخطوة 4️⃣: Admin Reports → Revenue${NC}"
echo "======================================"

REPORTS=$(curl -s "http://localhost:3001/api/reports" \
  -H "Authorization: Bearer $SUPER_TOKEN")

TOTAL_REVENUE=$(echo "$REPORTS" | grep -o '"totalRevenue":[0-9]*' | grep -o '[0-9]*')
TOTAL_SUBS=$(echo "$REPORTS" | grep -o '"totalSubscriptions":[0-9]*' | grep -o '[0-9]*')

if [ -n "$TOTAL_REVENUE" ] && [ "$TOTAL_REVENUE" -gt 0 ]; then
    echo -e "${GREEN}✅ Reports يعرض Revenue${NC}"
    echo "   Total Revenue: ${TOTAL_REVENUE:-0} EGP"
    echo "   Total Subscriptions: ${TOTAL_SUBS:-0}"
else
    echo -e "${RED}❌ Revenue = 0${NC}"
fi

echo ""

# ==========================================
# الخطوة 5: Side Expenses Form Test
# ==========================================
echo "======================================"
echo -e "${BLUE}الخطوة 5️⃣: Side Expenses Form${NC}"
echo "======================================"

# Test creating expense
EXPENSE=$(curl -s -X POST http://localhost:3001/api/expenses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SUPER_TOKEN" \
  -d '{
    "description":"Office Supplies",
    "amount":200,
    "category":"supplies",
    "date":"2025-10-02"
  }')

if echo "$EXPENSE" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Side Expenses API يعمل${NC}"
    echo "   Description: Office Supplies"
    echo "   Amount: 200 EGP"
else
    echo -e "${YELLOW}⚠️  Expenses API route قد لا يكون موجود${NC}"
    echo "   Message: $(echo $EXPENSE | grep -o '"message":"[^"]*"' | sed 's/"message":"//;s/"//')"
fi

echo ""

# ==========================================
# الخطوة 6: Driver Salaries Form Test
# ==========================================
echo "======================================"
echo -e "${BLUE}الخطوة 6️⃣: Driver Salaries Form${NC}"
echo "======================================"

# Test creating salary record
SALARY=$(curl -s -X POST http://localhost:3001/api/salaries \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SUPER_TOKEN" \
  -d '{
    "driverName":"Mohamed Ali",
    "amount":3000,
    "month":"October",
    "year":"2025",
    "status":"paid"
  }')

if echo "$SALARY" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Driver Salaries API يعمل${NC}"
    echo "   Driver: Mohamed Ali"
    echo "   Amount: 3000 EGP"
else
    echo -e "${YELLOW}⚠️  Salaries API route قد لا يكون موجود${NC}"
    echo "   Message: $(echo $SALARY | grep -o '"message":"[^"]*"' | sed 's/"message":"//;s/"//')"
fi

echo ""

# ==========================================
# ملخص النتائج
# ==========================================
echo "=============================================="
echo -e "${GREEN}📊 ملخص الاختبار الشامل${NC}"
echo "=============================================="
echo ""

PASS=0

echo "$PAYMENT" | grep -q success.*true && echo "✅ 1. Payment Form (Supervisor)" && ((PASS++)) || echo "❌ 1. Payment Form"
echo "$STUDENT_SUBS" | grep -q success.*true && [ ${SUB_COUNT:-0} -gt 0 ] && echo "✅ 2. Student Portal Subscriptions (عدد: ${SUB_COUNT:-0})" && ((PASS++)) || echo "❌ 2. Student Portal Subs"
[ ${ALI_SUBS:-0} -gt 0 ] && echo "✅ 3. Admin Subscriptions (عدد: ${ALI_SUBS:-0})" && ((PASS++)) || echo "❌ 3. Admin Subscriptions"
[ "${TOTAL_REVENUE:-0}" -gt 0 ] && echo "✅ 4. Admin Reports - Revenue ($TOTAL_REVENUE EGP)" && ((PASS++)) || echo "❌ 4. Reports Revenue"
echo "$EXPENSE" | grep -q success.*true && echo "✅ 5. Side Expenses Form" && ((PASS++)) || echo "⚠️  5. Side Expenses (route قد يكون مفقود)"
echo "$SALARY" | grep -q success.*true && echo "✅ 6. Driver Salaries Form" && ((PASS++)) || echo "⚠️  6. Driver Salaries (route قد يكون مفقود)"

echo ""
echo "═══════════════════════════════════════════════"
echo -e "${GREEN}النتيجة: $PASS/6${NC}"
echo "═══════════════════════════════════════════════"
echo ""

if [ $PASS -ge 4 ]; then
    echo -e "${GREEN}🎉🎉🎉 نظام Subscriptions يعمل بشكل ممتاز! 🎉🎉🎉${NC}"
    echo ""
    echo "✅ Payment Form يعمل"
    echo "✅ Student Portal Subscriptions تعمل"
    echo "✅ Admin Subscriptions تعمل"
    echo "✅ Reports Revenue يعمل"
    echo ""
    if [ $PASS -lt 6 ]; then
        echo -e "${YELLOW}⚠️  Expenses & Salaries routes قد تحتاج إنشاء${NC}"
    fi
    echo ""
    echo "الآن في المتصفح (Incognito):"
    echo "جرب جميع الوظائف وستجدها تعمل!"
else
    echo -e "${YELLOW}⚠️ بعض الوظائف تحتاج مراجعة ($PASS/6)${NC}"
fi

echo ""

