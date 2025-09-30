import { NextResponse } from 'next/server';

export function middleware(request) {
  // Redirect /auth to /login
  if (request.nextUrl.pathname === '/auth') {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  
  return NextResponse.next();
}

export const config = {
  matcher: '/auth'
};