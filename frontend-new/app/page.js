'use client';

import React from 'react';
import { LanguageProvider } from '../lib/contexts/LanguageContext';

export default function HomePage() {
  return (
    <LanguageProvider>
      <div style={{
        minHeight: '100vh',
        width: '100vw',
        background: `
          linear-gradient(135deg, rgba(0,0,0,0.2) 0%, rgba(0,0,0,0.3) 100%),
          url('/unibusbackground.jpg')
        `,
        backgroundSize: 'cover',
        backgroundPosition: 'center',
        backgroundRepeat: 'no-repeat',
        backgroundAttachment: 'fixed',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '20px',
        fontFamily: 'system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, Noto Sans, Helvetica Neue, Arial, sans-serif',
        position: 'relative',
        overflow: 'hidden'
      }}>
        {/* 3D Geometric Shapes Background */}
        <div style={{
          position: 'absolute',
          top: 0,
          left: 0,
          width: '100%',
          height: '100%',
          pointerEvents: 'none',
          zIndex: 1
        }}>
          {/* Floating 3D Cubes */}
          <div style={{
            position: 'absolute',
            top: '10%',
            left: '5%',
            width: '70px',
            height: '70px',
            background: 'linear-gradient(135deg, #ffd700, #ffed4e)',
            transform: 'rotate(45deg) perspective(1000px) rotateX(20deg) rotateY(20deg)',
            boxShadow: '0 25px 50px rgba(255, 215, 0, 0.4), inset 0 2px 4px rgba(255,255,255,0.3)',
            animation: 'float 6s ease-in-out infinite',
            border: '2px solid rgba(255,255,255,0.2)'
          }}></div>
          
          <div style={{
            position: 'absolute',
            top: '20%',
            right: '10%',
            width: '90px',
            height: '90px',
            background: 'linear-gradient(135deg, #4f46e5, #7c3aed)',
            transform: 'rotate(30deg) perspective(1000px) rotateX(15deg) rotateY(-15deg)',
            boxShadow: '0 30px 60px rgba(79, 70, 229, 0.5), inset 0 2px 4px rgba(255,255,255,0.2)',
            animation: 'float 8s ease-in-out infinite reverse',
            border: '2px solid rgba(255,255,255,0.15)'
          }}></div>
          
          <div style={{
            position: 'absolute',
            bottom: '15%',
            left: '8%',
            width: '70px',
            height: '70px',
            background: 'linear-gradient(135deg, #10b981, #34d399)',
            transform: 'rotate(60deg) perspective(1000px) rotateX(-20deg) rotateY(30deg)',
            boxShadow: '0 30px 60px rgba(16, 185, 129, 0.4)',
            animation: 'float 7s ease-in-out infinite'
          }}></div>
          
          <div style={{
            position: 'absolute',
            bottom: '25%',
            right: '15%',
            width: '50px',
            height: '50px',
            background: 'linear-gradient(135deg, #f59e0b, #fbbf24)',
            transform: 'rotate(15deg) perspective(1000px) rotateX(25deg) rotateY(-25deg)',
            boxShadow: '0 15px 30px rgba(245, 158, 11, 0.3)',
            animation: 'float 9s ease-in-out infinite reverse'
          }}></div>
          
          {/* 3D Spheres */}
          <div style={{
            position: 'absolute',
            top: '30%',
            left: '15%',
            width: '40px',
            height: '40px',
            background: 'radial-gradient(circle at 30% 30%, #ffffff, #e5e7eb)',
            borderRadius: '50%',
            boxShadow: '0 20px 40px rgba(0,0,0,0.3), inset 0 5px 10px rgba(255,255,255,0.5)',
            animation: 'bounce 4s ease-in-out infinite'
          }}></div>
          
          <div style={{
            position: 'absolute',
            top: '60%',
            right: '20%',
            width: '60px',
            height: '60px',
            background: 'radial-gradient(circle at 30% 30%, #fbbf24, #f59e0b)',
            borderRadius: '50%',
            boxShadow: '0 25px 50px rgba(251, 191, 36, 0.4), inset 0 5px 10px rgba(255,255,255,0.3)',
            animation: 'bounce 5s ease-in-out infinite reverse'
          }}></div>
        </div>

        {/* Main Content */}
        <div style={{
          width: '100%',
          maxWidth: '800px',
          textAlign: 'center',
          color: 'white',
          position: 'relative',
          zIndex: 2
        }}>
          {/* Enhanced Glass card with 3D effects */}
          <div style={{
            backdropFilter: 'blur(20px)',
            WebkitBackdropFilter: 'blur(20px)',
            background: 'linear-gradient(180deg, rgba(255,255,255,0.25), rgba(255,255,255,0.15))',
            border: '2px solid rgba(255,255,255,0.4)',
            borderRadius: '32px',
            padding: '60px 50px',
            boxShadow: `
              0 40px 80px rgba(0,0,0,0.4),
              inset 0 1px 0 rgba(255,255,255,0.2),
              0 0 0 1px rgba(255,255,255,0.1)
            `,
            transform: 'perspective(1000px) rotateX(2deg)',
            position: 'relative',
            overflow: 'hidden'
          }}>
            {/* Animated background pattern */}
            <div style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: '100%',
              background: `
                radial-gradient(circle at 20% 20%, rgba(255,255,255,0.1) 0%, transparent 50%),
                radial-gradient(circle at 80% 80%, rgba(255,255,255,0.1) 0%, transparent 50%)
              `,
              animation: 'shimmer 3s ease-in-out infinite'
            }}></div>

            {/* Enhanced UniBus logo with 3D effect */}
            <div style={{
              width: '140px',
              height: '140px',
              margin: '0 auto 24px auto',
              borderRadius: '35px',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              background: 'linear-gradient(135deg, #fee440, #ffd166)',
              boxShadow: `
                0 25px 50px rgba(254, 228, 64, 0.6),
                inset 0 3px 6px rgba(255,255,255,0.4),
                0 0 0 2px rgba(255,255,255,0.3)
              `,
              transform: 'perspective(1000px) rotateY(-5deg) rotateX(5deg)',
              animation: 'logoFloat 4s ease-in-out infinite',
              position: 'relative',
              overflow: 'hidden'
            }}>
              {/* UniBus Logo Text */}
              <div style={{
                fontSize: '32px',
                fontWeight: '900',
                color: '#1e293b',
                textShadow: '0 2px 4px rgba(0,0,0,0.2)',
                letterSpacing: '-1px',
                lineHeight: '1',
                marginBottom: '4px'
              }}>UB</div>
              <div style={{
                fontSize: '12px',
                fontWeight: '700',
                color: '#475569',
                textShadow: '0 1px 2px rgba(0,0,0,0.1)',
                letterSpacing: '1px'
              }}>UNIBUS</div>
              
              {/* Decorative elements */}
              <div style={{
                position: 'absolute',
                top: '8px',
                right: '8px',
                width: '8px',
                height: '8px',
                background: 'rgba(30, 41, 59, 0.3)',
                borderRadius: '50%'
              }}></div>
              <div style={{
                position: 'absolute',
                bottom: '8px',
                left: '8px',
                width: '6px',
                height: '6px',
                background: 'rgba(30, 41, 59, 0.2)',
                borderRadius: '50%'
              }}></div>
            </div>

            <h1 style={{
              fontSize: '68px',
              lineHeight: 1.05,
              fontWeight: 900,
              letterSpacing: '-0.02em',
              margin: '0 0 16px 0',
              color: '#ffffff',
              textShadow: '0 6px 12px rgba(0,0,0,0.5), 0 2px 4px rgba(0,0,0,0.3)',
              transform: 'perspective(1000px) rotateX(2deg)',
              filter: 'drop-shadow(0 4px 8px rgba(0,0,0,0.4))'
            }}>UniBus</h1>

            <p style={{
              margin: 0,
              color: '#f8fafc',
              fontSize: '24px',
              fontWeight: 600,
              textShadow: '0 4px 8px rgba(0,0,0,0.4), 0 2px 4px rgba(0,0,0,0.2)',
              filter: 'drop-shadow(0 2px 4px rgba(0,0,0,0.3))'
            }}>Student Transportation Portal</p>

            {/* Enhanced CTA Button with 3D effects */}
            <div style={{ marginTop: '40px' }}>
              <a href="/login" style={{
                display: 'inline-block',
                padding: '20px 32px',
                borderRadius: '20px',
                color: '#0b1020',
                background: 'linear-gradient(135deg, #a7f3d0, #34d399, #10b981)',
                textDecoration: 'none',
                fontWeight: 800,
                fontSize: '20px',
                boxShadow: `
                  0 20px 40px rgba(52,211,153,0.4),
                  inset 0 2px 4px rgba(255,255,255,0.3),
                  0 0 0 1px rgba(255,255,255,0.2)
                `,
                transform: 'perspective(1000px) rotateX(5deg)',
                transition: 'all 0.3s ease',
                position: 'relative',
                overflow: 'hidden'
              }}
              onMouseOver={(e) => {
                e.target.style.transform = 'perspective(1000px) rotateX(0deg) scale(1.05)';
                e.target.style.boxShadow = '0 25px 50px rgba(52,211,153,0.5), inset 0 2px 4px rgba(255,255,255,0.4)';
              }}
              onMouseOut={(e) => {
                e.target.style.transform = 'perspective(1000px) rotateX(5deg) scale(1)';
                e.target.style.boxShadow = '0 20px 40px rgba(52,211,153,0.4), inset 0 2px 4px rgba(255,255,255,0.3)';
              }}
              >
                <span style={{
                  display: 'inline-block',
                  transform: 'rotate(-5deg)',
                  marginRight: '8px'
                }}>🚀</span>
                Enter Portal
              </a>
            </div>
          </div>
        </div>

        {/* CSS Animations */}
        <style jsx>{`
          @keyframes float {
            0%, 100% { transform: translateY(0px) rotate(0deg); }
            50% { transform: translateY(-20px) rotate(180deg); }
          }
          
          @keyframes bounce {
            0%, 100% { transform: translateY(0px) scale(1); }
            50% { transform: translateY(-15px) scale(1.1); }
          }
          
          @keyframes shimmer {
            0% { opacity: 0.3; }
            50% { opacity: 0.6; }
            100% { opacity: 0.3; }
          }
          
          @keyframes logoFloat {
            0%, 100% { transform: perspective(1000px) rotateY(-5deg) rotateX(5deg) translateY(0px); }
            50% { transform: perspective(1000px) rotateY(5deg) rotateX(-5deg) translateY(-5px); }
          }
        `}</style>
      </div>
    </LanguageProvider>
  );
}