import React from 'react';

interface StatsRingProps {
  value: number;
  maxValue: number;
  label: string;
  size?: number;
  color?: string;
}

export function StatsRing({ 
  value, 
  maxValue, 
  label, 
  size = 120,
  color = '#1976D2' 
}: StatsRingProps) {
  const percentage = (value / maxValue) * 100;
  const circumference = 2 * Math.PI * 45;
  const strokeDashoffset = circumference - (percentage / 100) * circumference;

  return (
    <div className="flex flex-col items-center">
      <div className="relative" style={{ width: size, height: size }}>
        <svg className="transform -rotate-90" width={size} height={size}>
          <circle
            cx={size / 2}
            cy={size / 2}
            r="45"
            stroke="#E0E0E0"
            strokeWidth="8"
            fill="none"
          />
          <circle
            cx={size / 2}
            cy={size / 2}
            r="45"
            stroke={color}
            strokeWidth="8"
            fill="none"
            strokeDasharray={circumference}
            strokeDashoffset={strokeDashoffset}
            strokeLinecap="round"
            className="transition-all duration-500"
          />
        </svg>
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span className="text-[#212121]" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '1.5rem' }}>
            {value}
          </span>
        </div>
      </div>
      <p className="mt-2 text-[#757575] text-center" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
        {label}
      </p>
    </div>
  );
}
