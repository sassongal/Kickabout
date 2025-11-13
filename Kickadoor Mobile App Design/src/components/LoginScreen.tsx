import React, { useState } from 'react';
import { FuturisticCard } from './FuturisticCard';
import { GradientButton } from './GradientButton';
import { LogIn, UserPlus } from 'lucide-react';
import { Input } from './ui/input';
import { Label } from './ui/label';

interface LoginScreenProps {
  onLogin: () => void;
}

export function LoginScreen({ onLogin }: LoginScreenProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  return (
    <div className="min-h-screen bg-[#F5F5F5] flex flex-col items-center justify-center p-6">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="mb-8 flex flex-col items-center">
          <div className="relative mb-4">
            <img 
              src="https://images.unsplash.com/photo-1650327987377-90bf6c9789fd?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzb2NjZXIlMjBiYWxsJTIwZ3JlZW4lMjBmaWVsZHxlbnwxfHx8fDE3NjI5OTE3NzR8MA&ixlib=rb-4.1.0&q=80&w=200" 
              alt="Soccer Ball" 
              className="w-24 h-24 rounded-full object-cover border-4 border-[#4CAF50]"
            />
          </div>
          <h1 
            className="text-center text-[#212121] uppercase tracking-widest mb-2" 
            style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 900, fontSize: '2rem', letterSpacing: '0.15em', color: '#1976D2' }}
          >
            KICKADOOR
          </h1>
          <p className="text-[#757575] text-center" style={{ fontFamily: 'Inter, sans-serif' }}>
            רשת חברתית לשחקני כדורגל שכונתי
          </p>
        </div>

        {/* Welcome Text */}
        <h2 
          className="text-center text-[#212121] mb-8 uppercase tracking-widest" 
          style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, letterSpacing: '0.15em' }}
        >
          WELCOME
        </h2>

        {/* Quick Access Buttons */}
        <div className="space-y-3 mb-6">
          <GradientButton 
            variant="primary" 
            icon={<UserPlus />}
            onClick={onLogin}
            className="w-full"
          >
            Continue as Guest
          </GradientButton>
          <GradientButton 
            variant="secondary" 
            icon={<LogIn />}
            onClick={onLogin}
            className="w-full"
          >
            Sign in with Google
          </GradientButton>
        </div>

        {/* Login Form */}
        <FuturisticCard>
          <div className="space-y-4">
            <div>
              <Label htmlFor="email" className="text-[#757575]">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="your@email.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="mt-1"
              />
            </div>
            <div>
              <Label htmlFor="password" className="text-[#757575]">Password</Label>
              <Input
                id="password"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="mt-1"
              />
            </div>
            <GradientButton 
              variant="primary" 
              onClick={onLogin}
              className="w-full"
            >
              Sign In
            </GradientButton>
          </div>
        </FuturisticCard>

        {/* Sign Up Link */}
        <p className="text-center mt-6 text-[#757575]" style={{ fontFamily: 'Inter, sans-serif' }}>
          Don't have an account?{' '}
          <button 
            className="text-[#1976D2]" 
            style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 600 }}
            onClick={onLogin}
          >
            Sign Up
          </button>
        </p>
      </div>
    </div>
  );
}
