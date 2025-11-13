import React from 'react';

interface PlayerAvatarProps {
  name: string;
  imageUrl?: string;
  status?: 'available' | 'busy' | 'unavailable';
  size?: 'sm' | 'md' | 'lg' | 'xl';
}

export function PlayerAvatar({ name, imageUrl, status, size = 'md' }: PlayerAvatarProps) {
  const sizes = {
    sm: 'w-10 h-10',
    md: 'w-16 h-16',
    lg: 'w-24 h-24',
    xl: 'w-32 h-32'
  };

  const statusColors = {
    available: '#4CAF50',
    busy: '#FF9800',
    unavailable: '#F44336'
  };

  const ringSize = {
    sm: 'w-11 h-11',
    md: 'w-[68px] h-[68px]',
    lg: 'w-[100px] h-[100px]',
    xl: 'w-[136px] h-[136px]'
  };

  const initials = name
    .split(' ')
    .map(word => word[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);

  return (
    <div className="relative inline-block">
      {status && (
        <div
          className={`absolute inset-0 rounded-full ${ringSize[size]} -translate-x-1 -translate-y-1`}
          style={{
            background: `conic-gradient(${statusColors[status]} 0deg 270deg, transparent 270deg 360deg)`,
            padding: '2px'
          }}
        />
      )}
      <div className={`${sizes[size]} rounded-full bg-gradient-to-br from-[#1976D2] to-[#9C27B0] flex items-center justify-center relative z-10`}>
        {imageUrl ? (
          <img src={imageUrl} alt={name} className="w-full h-full rounded-full object-cover" />
        ) : (
          <span className="text-white" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700 }}>
            {initials}
          </span>
        )}
      </div>
    </div>
  );
}
