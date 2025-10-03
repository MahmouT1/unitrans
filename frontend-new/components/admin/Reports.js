import React, { useState, useEffect } from 'react';
import './Reports.css';

const Reports = () => {
  const [activeSection, setActiveSection] = useState('revenue');
  const [selectedWeek, setSelectedWeek] = useState(0); // 0 = current week, 1 = previous week, etc.
  const [loading, setLoading] = useState(true);
  
  // Data states
  const [revenueData, setRevenueData] = useState([]);
  const [expenseData, setExpenseData] = useState([]);
  const [driverSalaryData, setDriverSalaryData] = useState([]);
  const [summaryStats, setSummaryStats] = useState({
    totalRevenue: 0,
    totalExpenses: 0,
    totalDriverSalaries: 0,
    netProfit: 0
  });

  // Form states for sidebar
  const [showExpenseForm, setShowExpenseForm] = useState(false);
  const [showDriverSalaryForm, setShowDriverSalaryForm] = useState(false);
  const [expenseForm, setExpenseForm] = useState({
    type: '',
    amount: '',
    date: new Date().toISOString().split('T')[0],
    description: '',
    category: 'fuel',
    paymentMethod: 'cash',
    vendor: '',
    receiptUrl: ''
  });
  const [driverSalaryForm, setDriverSalaryForm] = useState({
    driverName: '',
    amount: '',
    date: new Date().toISOString().split('T')[0],
    hoursWorked: '',
    ratePerHour: '',
    paymentMethod: 'cash',
    notes: ''
  });

  // Get current week date range
  const getWeekDateRange = (weekOffset = 0) => {
    const now = new Date();
    const currentWeekStart = new Date(now);
    currentWeekStart.setDate(now.getDate() - now.getDay() + (weekOffset * 7));
    currentWeekStart.setHours(0, 0, 0, 0);
    
    const currentWeekEnd = new Date(currentWeekStart);
    currentWeekEnd.setDate(currentWeekStart.getDate() + 6);
    currentWeekEnd.setHours(23, 59, 59, 999);
    
    return {
      start: currentWeekStart.toISOString().split('T')[0],
      end: currentWeekEnd.toISOString().split('T')[0],
      label: weekOffset === 0 ? 'Current Week' : `Week ${weekOffset} ago`
    };
  };

  const currentWeek = getWeekDateRange(selectedWeek);

  // Fetch all data using Frontend API routes only
  const fetchData = async () => {
    setLoading(true);
    try {
      console.log('📊 Fetching financial reports...');
      
      // Fetch all data using Frontend API routes
      const [revenueRes, expenseRes, driverRes] = await Promise.all([
        fetch('/api/subscriptions'),
        fetch(`/api/expenses?startDate=${currentWeek.start}&endDate=${currentWeek.end}`),
        fetch(`/api/driver-salaries?startDate=${currentWeek.start}&endDate=${currentWeek.end}`)
      ]);

      const [revenueData, expenseData, driverData] = await Promise.all([
        revenueRes.json(),
        expenseRes.json(),
        driverRes.json()
      ]);

      console.log('💰 Revenue data:', revenueData);
      console.log('💸 Expense data:', expenseData);
      console.log('👨‍💼 Driver salary data:', driverData);

      // Handle subscriptions
      let subscriptions = [];
      if (revenueData.success) {
        subscriptions = revenueData.subscriptions || [];
      }
      setRevenueData(subscriptions);

      // Handle expenses
      let expenses = [];
      if (expenseData.success) {
        expenses = expenseData.expenses || [];
      }
      setExpenseData(expenses);

      // Handle driver salaries
      let salaries = [];
      if (driverData.success) {
        salaries = driverData.salaries || [];
      }
      setDriverSalaryData(salaries);

      // Calculate summary stats - sum all subscription amounts
      const totalRevenue = subscriptions.reduce((sum, sub) => sum + (sub.amount || 0), 0);
      const totalExpenses = expenses.reduce((sum, exp) => sum + (exp.amount || 0), 0);
      const totalDriverSalaries = salaries.reduce((sum, sal) => sum + (sal.amount || 0), 0);
      const netProfit = totalRevenue - totalExpenses - totalDriverSalaries;

      console.log('📈 Financial Summary:', {
        totalRevenue,
        totalExpenses,
        totalDriverSalaries,
        netProfit
      });

      setSummaryStats({
        totalRevenue,
        totalExpenses,
        totalDriverSalaries,
        netProfit
      });

    } catch (error) {
      console.error('❌ Error fetching financial data:', error);
      setSummaryStats({
        totalRevenue: 0,
        totalExpenses: 0,
        totalDriverSalaries: 0,
        netProfit: 0
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [selectedWeek]);

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-EG', {
      style: 'currency',
      currency: 'EGP'
    }).format(amount);
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const handlePrint = () => {
    const printContent = document.getElementById('reports-content');
    const originalContent = document.body.innerHTML;
    document.body.innerHTML = printContent.innerHTML;
    window.print();
    document.body.innerHTML = originalContent;
    window.location.reload();
  };

  // Handle expense form submission
  const handleExpenseSubmit = async (e) => {
    e.preventDefault();
    try {
      const response = await fetch('/api/expenses', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          title: expenseForm.type, // Map type to title (required field)
          description: expenseForm.description,
          amount: parseFloat(expenseForm.amount),
          category: expenseForm.category,
          date: expenseForm.date,
          paymentMethod: expenseForm.paymentMethod,
          vendor: expenseForm.vendor,
          createdBy: 'admin' // You can get this from auth context
        })
      });

      if (response.ok) {
        console.log('✅ Expense added successfully');
        alert('Expense added successfully!');
        setExpenseForm({
          type: '',
          amount: '',
          date: new Date().toISOString().split('T')[0],
          description: '',
          category: 'fuel',
          paymentMethod: 'cash',
          vendor: '',
          receiptUrl: ''
        });
        setShowExpenseForm(false);
        fetchData(); // Refresh the data
      } else {
        console.error('❌ Failed to add expense');
        alert('Failed to add expense');
      }
    } catch (error) {
      console.error('❌ Error adding expense:', error);
      alert('Error adding expense: ' + error.message);
    }
  };

  // Handle driver salary form submission
  const handleDriverSalarySubmit = async (e) => {
    e.preventDefault();
    try {
      const response = await fetch('/api/driver-salaries', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          ...driverSalaryForm,
          amount: parseFloat(driverSalaryForm.amount),
          hoursWorked: parseFloat(driverSalaryForm.hoursWorked || 0),
          ratePerHour: parseFloat(driverSalaryForm.ratePerHour || 0),
          createdBy: 'admin' // You can get this from auth context
        })
      });

      if (response.ok) {
        console.log('✅ Driver salary added successfully');
        alert('Driver salary added successfully!');
        setDriverSalaryForm({
          driverName: '',
          amount: '',
          date: new Date().toISOString().split('T')[0],
          hoursWorked: '',
          ratePerHour: '',
          paymentMethod: 'cash',
          notes: ''
        });
        setShowDriverSalaryForm(false);
        fetchData(); // Refresh the data
      } else {
        console.error('❌ Failed to add driver salary');
        alert('Failed to add driver salary');
      }
    } catch (error) {
      console.error('❌ Error adding driver salary:', error);
    }
  };


  if (loading) {
    return (
      <div className="reports-loading">
        <div className="loading-spinner"></div>
        <p>Loading reports data...</p>
      </div>
    );
  }

  return (
    <div className="reports-container">
      <div className="reports-main-content">
        {/* Header */}
        <div className="reports-header">
        <div className="header-content">
          <h1>Financial Reports</h1>
          <p>Comprehensive financial overview and analysis</p>
        </div>
        <div className="header-actions">
          <div className="week-selector">
            <label>Week:</label>
            <select 
              value={selectedWeek} 
              onChange={(e) => setSelectedWeek(parseInt(e.target.value))}
            >
              <option value={0}>Current Week</option>
              <option value={1}>1 Week Ago</option>
              <option value={2}>2 Weeks Ago</option>
              <option value={3}>3 Weeks Ago</option>
              <option value={4}>4 Weeks Ago</option>
            </select>
          </div>
          <button onClick={handlePrint} className="print-btn">
            🖨️ Print Report
          </button>
        </div>
      </div>

      {/* Summary Stats */}
      <div className="summary-stats">
        <div className="stat-card revenue">
          <div className="stat-icon">💰</div>
          <div className="stat-content">
            <div className="stat-label">Total Revenue</div>
            <div className="stat-value">{formatCurrency(summaryStats.totalRevenue)}</div>
            <div className="stat-subtext">{currentWeek.label}</div>
          </div>
        </div>
        <div className="stat-card expenses">
          <div className="stat-icon">💸</div>
          <div className="stat-content">
            <div className="stat-label">Side Expenses</div>
            <div className="stat-value">{formatCurrency(summaryStats.totalExpenses)}</div>
            <div className="stat-subtext">{currentWeek.label}</div>
          </div>
        </div>
        <div className="stat-card drivers">
          <div className="stat-icon">🚌</div>
          <div className="stat-content">
            <div className="stat-label">Driver Salaries</div>
            <div className="stat-value">{formatCurrency(summaryStats.totalDriverSalaries)}</div>
            <div className="stat-subtext">{currentWeek.label}</div>
          </div>
        </div>
        <div className="stat-card profit">
          <div className="stat-icon">📈</div>
          <div className="stat-content">
            <div className="stat-label">Net Profit</div>
            <div className="stat-value">{formatCurrency(summaryStats.netProfit)}</div>
            <div className="stat-subtext">{currentWeek.label}</div>
          </div>
        </div>
      </div>

      {/* Section Tabs */}
      <div className="section-tabs">
        <button 
          className={activeSection === 'revenue' ? 'active' : ''}
          onClick={() => setActiveSection('revenue')}
        >
          💰 Revenue
        </button>
        <button 
          className={activeSection === 'expenses' ? 'active' : ''}
          onClick={() => setActiveSection('expenses')}
        >
          💸 Side Expenses
        </button>
        <button 
          className={activeSection === 'drivers' ? 'active' : ''}
          onClick={() => setActiveSection('drivers')}
        >
          🚌 Driver Salaries
        </button>
        <button 
          className={activeSection === 'profit' ? 'active' : ''}
          onClick={() => setActiveSection('profit')}
        >
          📊 Net Profit
        </button>
      </div>

      {/* Reports Content */}
      <div id="reports-content" className="reports-content">
        {/* Revenue Section */}
        {activeSection === 'revenue' && (
          <div className="section-content">
            <div className="section-header">
              <h2>Revenue from Subscriptions</h2>
              <p>Student subscription payments for {currentWeek.label}</p>
            </div>
            <div className="table-container">
              <table className="reports-table">
                <thead>
                  <tr>
                    <th>Student Name</th>
                    <th>Email</th>
                    <th>Subscription Status</th>
                    <th>Amount Paid</th>
                    <th>Payment Date</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {revenueData.length === 0 ? (
                    <tr>
                      <td colSpan="6" className="no-data">
                        No subscription data found for this week
                      </td>
                    </tr>
                  ) : (
                    revenueData.map((subscription, index) => (
                      <tr key={index}>
                        <td>{subscription.studentName || 'N/A'}</td>
                        <td>{subscription.studentEmail || 'N/A'}</td>
                        <td>
                          <span className={`status-badge ${subscription.status || 'inactive'}`}>
                            {subscription.status || 'Inactive'}
                          </span>
                        </td>
                        <td className="amount positive">
                          {formatCurrency(subscription.totalPaid || 0)}
                        </td>
                        <td>{formatDate(subscription.lastPaymentDate || subscription.confirmationDate)}</td>
                        <td>
                          <button
                            onClick={async () => {
                              if (window.confirm(`Are you sure you want to delete the subscription for ${subscription.studentName || subscription.studentEmail}?`)) {
                                try {
                                  const token = localStorage.getItem('token');
                                  const response = await fetch(`/api/subscription/delete/${subscription.studentEmail}`, {
                                    method: 'DELETE',
                                    headers: {
                                      'Authorization': `Bearer ${token}`,
                                      'Content-Type': 'application/json'
                                    }
                                  });

                                  const result = await response.json();

                                  if (result.success) {
                                    alert(`Subscription for ${subscription.studentName || subscription.studentEmail} deleted successfully!`);
                                    // Refresh the data
                                    fetchData();
                                  } else {
                                    alert(`Failed to delete subscription: ${result.message}`);
                                  }
                                } catch (error) {
                                  console.error('Delete error:', error);
                                  alert('An error occurred while deleting the subscription');
                                }
                              }
                            }}
                            style={{
                              background: 'none',
                              border: 'none',
                              cursor: 'pointer',
                              padding: '8px',
                              borderRadius: '8px',
                              transition: 'all 0.2s ease',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              fontSize: '18px'
                            }}
                            onMouseOver={(e) => {
                              e.target.style.backgroundColor = '#fef2f2';
                              e.target.style.transform = 'scale(1.1)';
                            }}
                            onMouseOut={(e) => {
                              e.target.style.backgroundColor = 'transparent';
                              e.target.style.transform = 'scale(1)';
                            }}
                            title={`Delete subscription for ${subscription.studentName || subscription.studentEmail}`}
                          >
                            🗑️
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Side Expenses Section */}
        {activeSection === 'expenses' && (
          <div className="section-content">
            <div className="section-header">
              <h2>Side Expenses</h2>
              <div className="section-actions">
                <p className="section-note">
                  💡 Use the "Add Expense" button in the sidebar to add new expenses
                </p>
              </div>
            </div>
            <div className="table-container">
              <table className="reports-table">
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>Type</th>
                    <th>Description</th>
                    <th>Category</th>
                    <th>Amount</th>
                  </tr>
                </thead>
                <tbody>
                  {expenseData.length === 0 ? (
                    <tr>
                      <td colSpan="5" className="no-data">
                        No expenses recorded for this week
                      </td>
                    </tr>
                  ) : (
                    expenseData.map((expense) => (
                      <tr key={expense._id}>
                        <td>{formatDate(expense.date)}</td>
                        <td>
                          <span className="type-badge">
                            {(expense.title || expense.type || 'Unknown').replace('_', ' ').toUpperCase()}
                          </span>
                        </td>
                        <td>{expense.description}</td>
                        <td>{expense.category}</td>
                        <td className="amount negative">
                          {formatCurrency(expense.amount)}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Driver Salaries Section */}
        {activeSection === 'drivers' && (
          <div className="section-content">
            <div className="section-header">
              <h2>Driver Salaries</h2>
              <div className="section-actions">
                <p className="section-note">
                  💡 Use the "Add Driver Salary" button in the sidebar to add new driver salaries
                </p>
              </div>
            </div>
            <div className="table-container">
              <table className="reports-table">
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>Driver Name</th>
                    <th>Hours Worked</th>
                    <th>Rate/Hour</th>
                    <th>Amount</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {driverSalaryData.length === 0 ? (
                    <tr>
                      <td colSpan="6" className="no-data">
                        No driver salaries recorded for this week
                      </td>
                    </tr>
                  ) : (
                    driverSalaryData.map((salary) => (
                      <tr key={salary._id}>
                        <td>{formatDate(salary.date)}</td>
                        <td>{salary.driverName}</td>
                        <td>{salary.hoursWorked || 0} hrs</td>
                        <td>{formatCurrency(salary.ratePerHour || 0)}</td>
                        <td className="amount negative">
                          {formatCurrency(salary.amount)}
                        </td>
                        <td>
                          <span className={`status-badge ${salary.status}`}>
                            {salary.status}
                          </span>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Net Profit Section */}
        {activeSection === 'profit' && (
          <div className="section-content">
            <div className="section-header">
              <h2>Net Profit Analysis</h2>
              <p>Financial summary for {currentWeek.label}</p>
            </div>
            <div className="profit-analysis">
              <div className="profit-breakdown">
                <div className="profit-item">
                  <div className="profit-label">Total Revenue</div>
                  <div className="profit-value positive">
                    {formatCurrency(summaryStats.totalRevenue)}
                  </div>
                </div>
                <div className="profit-item">
                  <div className="profit-label">Side Expenses</div>
                  <div className="profit-value negative">
                    -{formatCurrency(summaryStats.totalExpenses)}
                  </div>
                </div>
                <div className="profit-item">
                  <div className="profit-label">Driver Salaries</div>
                  <div className="profit-value negative">
                    -{formatCurrency(summaryStats.totalDriverSalaries)}
                  </div>
                </div>
                <div className="profit-divider"></div>
                <div className="profit-item total">
                  <div className="profit-label">Net Profit</div>
                  <div className={`profit-value ${summaryStats.netProfit >= 0 ? 'positive' : 'negative'}`}>
                    {formatCurrency(summaryStats.netProfit)}
                  </div>
                </div>
              </div>
              <div className="profit-chart">
                <div className="chart-placeholder">
                  <p>📊 Profit visualization would go here</p>
                  <p>Revenue: {formatCurrency(summaryStats.totalRevenue)}</p>
                  <p>Total Expenses: {formatCurrency(summaryStats.totalExpenses + summaryStats.totalDriverSalaries)}</p>
                  <p>Net Profit: {formatCurrency(summaryStats.netProfit)}</p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
      </div>

      {/* Sidebar with Quick Action Forms */}
      <div className="reports-sidebar">
        <div className="sidebar-header">
          <h3>Quick Actions</h3>
          <p>Manage expenses and salaries</p>
        </div>
        
        <div className="sidebar-actions">
          <button 
            className={`sidebar-btn expense-btn ${showExpenseForm ? 'active' : ''}`}
            onClick={() => {
              setShowExpenseForm(!showExpenseForm);
              setShowDriverSalaryForm(false);
            }}
          >
            <span className="btn-icon">💸</span>
            <span className="btn-text">Add Expense</span>
            <span className="btn-arrow">{showExpenseForm ? '▼' : '▶'}</span>
          </button>
          
          <button 
            className={`sidebar-btn driver-btn ${showDriverSalaryForm ? 'active' : ''}`}
            onClick={() => {
              setShowDriverSalaryForm(!showDriverSalaryForm);
              setShowExpenseForm(false);
            }}
          >
            <span className="btn-icon">🚌</span>
            <span className="btn-text">Add Driver Salary</span>
            <span className="btn-arrow">{showDriverSalaryForm ? '▼' : '▶'}</span>
          </button>
        </div>

        {/* Expense Form */}
        {showExpenseForm && (
          <div className="sidebar-form expense-form">
            <div className="form-header">
              <h4>💸 Add New Expense</h4>
              <button 
                className="close-btn"
                onClick={() => setShowExpenseForm(false)}
              >
                ✕
              </button>
            </div>
            <form onSubmit={handleExpenseSubmit}>
              <div className="form-group">
                <label>Expense Type*</label>
                <input
                  type="text"
                  value={expenseForm.type}
                  onChange={(e) => setExpenseForm({...expenseForm, type: e.target.value})}
                  placeholder="e.g., Fuel, Maintenance, Office Supplies"
                  required
                />
              </div>
              
              <div className="form-group">
                <label>Amount (EGP)*</label>
                <input
                  type="number"
                  value={expenseForm.amount}
                  onChange={(e) => setExpenseForm({...expenseForm, amount: e.target.value})}
                  placeholder="0.00"
                  step="0.01"
                  required
                />
              </div>
              
              <div className="form-group">
                <label>Category*</label>
                <select
                  value={expenseForm.category}
                  onChange={(e) => setExpenseForm({...expenseForm, category: e.target.value})}
                  required
                >
                  <option value="fuel">Fuel</option>
                  <option value="maintenance">Maintenance</option>
                  <option value="office">Office Supplies</option>
                  <option value="utilities">Utilities</option>
                  <option value="marketing">Marketing</option>
                  <option value="insurance">Insurance</option>
                  <option value="other">Other</option>
                </select>
              </div>
              
              <div className="form-group">
                <label>Date*</label>
                <input
                  type="date"
                  value={expenseForm.date}
                  onChange={(e) => setExpenseForm({...expenseForm, date: e.target.value})}
                  required
                />
              </div>
              
              <div className="form-group">
                <label>Payment Method</label>
                <select
                  value={expenseForm.paymentMethod}
                  onChange={(e) => setExpenseForm({...expenseForm, paymentMethod: e.target.value})}
                >
                  <option value="cash">Cash</option>
                  <option value="bank_transfer">Bank Transfer</option>
                  <option value="credit_card">Credit Card</option>
                  <option value="check">Check</option>
                </select>
              </div>
              
              <div className="form-group">
                <label>Vendor</label>
                <input
                  type="text"
                  value={expenseForm.vendor}
                  onChange={(e) => setExpenseForm({...expenseForm, vendor: e.target.value})}
                  placeholder="Vendor/Supplier name"
                />
              </div>
              
              <div className="form-group">
                <label>Description</label>
                <textarea
                  value={expenseForm.description}
                  onChange={(e) => setExpenseForm({...expenseForm, description: e.target.value})}
                  placeholder="Brief description of the expense"
                  rows="3"
                />
              </div>
              
              <div className="form-actions">
                <button type="button" onClick={() => setShowExpenseForm(false)} className="cancel-btn">
                  Cancel
                </button>
                <button type="submit" className="submit-btn">
                  Add Expense
                </button>
              </div>
            </form>
          </div>
        )}

        {/* Driver Salary Form */}
        {showDriverSalaryForm && (
          <div className="sidebar-form driver-salary-form">
            <div className="form-header">
              <h4>🚌 Add Driver Salary</h4>
              <button 
                className="close-btn"
                onClick={() => setShowDriverSalaryForm(false)}
              >
                ✕
              </button>
            </div>
            <form onSubmit={handleDriverSalarySubmit}>
              <div className="form-group">
                <label>Driver Name*</label>
                <input
                  type="text"
                  value={driverSalaryForm.driverName}
                  onChange={(e) => setDriverSalaryForm({...driverSalaryForm, driverName: e.target.value})}
                  placeholder="Driver's full name"
                  required
                />
              </div>
              
              <div className="form-group">
                <label>Amount (EGP)*</label>
                <input
                  type="number"
                  value={driverSalaryForm.amount}
                  onChange={(e) => setDriverSalaryForm({...driverSalaryForm, amount: e.target.value})}
                  placeholder="0.00"
                  step="0.01"
                  required
                />
              </div>
              
              <div className="form-group">
                <label>Hours Worked</label>
                <input
                  type="number"
                  value={driverSalaryForm.hoursWorked}
                  onChange={(e) => setDriverSalaryForm({...driverSalaryForm, hoursWorked: e.target.value})}
                  placeholder="Total hours"
                  step="0.5"
                />
              </div>
              
              <div className="form-group">
                <label>Rate per Hour (EGP)</label>
                <input
                  type="number"
                  value={driverSalaryForm.ratePerHour}
                  onChange={(e) => setDriverSalaryForm({...driverSalaryForm, ratePerHour: e.target.value})}
                  placeholder="Hourly rate"
                  step="0.01"
                />
              </div>
              
              <div className="form-group">
                <label>Date*</label>
                <input
                  type="date"
                  value={driverSalaryForm.date}
                  onChange={(e) => setDriverSalaryForm({...driverSalaryForm, date: e.target.value})}
                  required
                />
              </div>
              
              <div className="form-group">
                <label>Payment Method</label>
                <select
                  value={driverSalaryForm.paymentMethod}
                  onChange={(e) => setDriverSalaryForm({...driverSalaryForm, paymentMethod: e.target.value})}
                >
                  <option value="cash">Cash</option>
                  <option value="bank_transfer">Bank Transfer</option>
                  <option value="check">Check</option>
                </select>
              </div>
              
              <div className="form-group">
                <label>Notes</label>
                <textarea
                  value={driverSalaryForm.notes}
                  onChange={(e) => setDriverSalaryForm({...driverSalaryForm, notes: e.target.value})}
                  placeholder="Additional notes or details"
                  rows="3"
                />
              </div>
              
              <div className="form-actions">
                <button type="button" onClick={() => setShowDriverSalaryForm(false)} className="cancel-btn">
                  Cancel
                </button>
                <button type="submit" className="submit-btn">
                  Add Salary
                </button>
              </div>
            </form>
          </div>
        )}
      </div>

    </div>
  );
};

export default Reports;
