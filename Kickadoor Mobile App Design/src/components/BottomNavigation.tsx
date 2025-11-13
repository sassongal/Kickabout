import React from 'react';
import { Home, Calendar, Map, Users, User } from 'lucide-react';

interface BottomNavigationProps {
  currentScreen: string;
  onNavigate: (screen: string) => void;
}

export function BottomNavigation({ currentScreen, onNavigate }: BottomNavigationProps) {
  const navItems = [
    { id: 'home', label: 'בית', icon: Home },
    { id: 'games', label: 'משחקים', icon: Calendar },
    { id: 'map', label: 'מפה', icon: Map },
    { id: 'hubs', label: 'קהילות', icon: Users },
    { id: 'profile', label: 'פרופיל', icon: User },
  ];

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-[#E0E0E0] px-4 py-2 max-w-md mx-auto">
      <div className="flex items-center justify-around">
        {navItems.map(({ id, label, icon: Icon }) => {
          const isActive = currentScreen === id;
          return (
            <button
              key={id}
              onClick={() => onNavigate(id)}
              className={`flex flex-col items-center gap-1 py-2 px-3 rounded-lg transition-colors ${
                isActive ? 'text-[#1976D2]' : 'text-[#757575]'
              }`}
            >
              <Icon className={`w-6 h-6 ${isActive ? 'fill-[#1976D2]/10' : ''}`} />
              <span style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.75rem' }}>
                {label}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
