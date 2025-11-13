import React from 'react';

interface FuturisticCardProps {
  children: React.ReactNode;
  className?: string;
  glow?: boolean;
}

export function FuturisticCard({ children, className = '', glow = false }: FuturisticCardProps) {
  return (
    <div
      className={`bg-white rounded-lg border-[1.5px] border-[#E0E0E0] p-4 ${
        glow ? 'shadow-[0_0_20px_rgba(76,175,80,0.15)]' : 'shadow-md'
      } ${className}`}
    >
      {children}
    </div>
  );
}
