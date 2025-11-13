import React from 'react';

interface GradientButtonProps {
  children: React.ReactNode;
  onClick?: () => void;
  icon?: React.ReactNode;
  variant?: 'primary' | 'secondary' | 'accent';
  className?: string;
}

export function GradientButton({ 
  children, 
  onClick, 
  icon, 
  variant = 'primary',
  className = '' 
}: GradientButtonProps) {
  const gradients = {
    primary: 'bg-gradient-to-r from-[#1976D2] to-[#1565C0]',
    secondary: 'bg-gradient-to-r from-[#4CAF50] to-[#388E3C]',
    accent: 'bg-gradient-to-r from-[#9C27B0] to-[#7B1FA2]'
  };

  return (
    <button
      onClick={onClick}
      className={`${gradients[variant]} text-white px-6 py-3 rounded-lg flex items-center justify-center gap-2 hover:opacity-90 transition-opacity ${className}`}
    >
      {icon && <span className="text-xl">{icon}</span>}
      <span className="uppercase tracking-wide" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700 }}>
        {children}
      </span>
    </button>
  );
}
